import 'dart:typed_data';
import 'dart:math';

import 'package:Routine/services/browser_config.dart';
import 'package:Routine/util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Directory, File, Platform, Process, ProcessResult, Socket, SocketException;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:async';
import 'package:Routine/setup.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Routine/services/strict_mode_service.dart';


class BrowserConnection {
  final Socket socket;
  List<int> buffer = [];
  int? len;

  BrowserConnection({required this.socket});
}

class BrowserExtensionService {
  static final BrowserExtensionService _instance = BrowserExtensionService._internal();
  final Map<Browser, BrowserConnection> _connections = {};
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  static const String _connectedBrowsersKey = 'connected_browsers';
  
  factory BrowserExtensionService() {
    return _instance;
  }
  
  BrowserExtensionService._internal();
  
  static BrowserExtensionService get instance => _instance;
  
  bool get isExtensionConnected => _connections.values.isNotEmpty;
  
  bool isBrowserConnected(Browser browser) {
    return _connections.containsKey(browser);
  }
  
  List<Browser> get connectedBrowsers {
    return _connections.keys.toList();
  }

  BrowserData getBrowserData(Browser browser) {
    return browserData[browser]!;
  }
  
  Future<List<Browser>> getInstalledSupportedBrowsers() async {
    List<Browser> supportedBrowsers = [];
    
    try {
      if (Platform.isMacOS) {
        final Directory appDir = Directory('/Applications');
        if (await appDir.exists()) {
          final entities = await appDir.list().toList();
          for (var entity in entities) {
            if (entity is Directory && entity.path.endsWith('.app')) {
              final lowerPath = entity.path.toLowerCase();

              final browser = Browser.values.firstWhereOrNull((b) => lowerPath.contains(b.name));

              if (browser != null) {
                supportedBrowsers.add(browser);
              }
            }
          }
        }
      } else if (Platform.isWindows) {
        for (final entry in browserData.entries) {
          for (final path in entry.value.windowsPaths) {
            final dir = Directory(path);
            if (await dir.exists()) {
              supportedBrowsers.add(entry.key);
              break;
            }
          }
        }
      }
    } catch (e, st) {
      Util.report('Error detecting browsers', e, st);
    }
    
    return supportedBrowsers;
  }

  Future<String> _getBinaryAssetPath() async {
    if (Platform.isMacOS) {
      final ProcessResult result = await Process.run('uname', ['-m']);
      final String arch = result.stdout.toString().trim();
      logger.i('Detected architecture: $arch');
      return arch == 'arm64' ? 'native_macos_arm64' : 'native_macos_x86_64';
    } else if (Platform.isWindows) {
      return 'native_windows.exe';
    } else if (Platform.isLinux) {
      return 'native_linux';
    }
    throw UnsupportedError('Unsupported platform');
  }

  Map<String, dynamic> _createManifestContent(Browser browser, String binaryPath) {
    return {
      'name': 'com.solidsoft.routine',
      'description': 'Routine Native Messaging Host',
      'path': binaryPath,
      'type': 'stdio',
      (browser == Browser.firefox ? 'allowed_extensions' : 'allowed_origins'): (browser == Browser.firefox ? ['blocker@routineblocker.com'] : ['chrome-extension://jdemcmodknkdcnkglkilkobkcboeaeib/'])
    };
  }

  Future<bool> installNativeMessagingHost(Browser browser) async {
    try {
      final data = browserData[browser]!;


      if (Platform.isMacOS) {
        final String nmhName = await _getBinaryAssetPath();
        
        final Map<String, dynamic> manifest = _createManifestContent(browser, '$assetsPath/$nmhName');
        final String manifestJson = json.encode(manifest);

        final fileName = 'com.solidsoft.routine.json';
        final nmhDir = data.macosNmhDir;
        
        final path = await FilePicker.platform.saveFile(
          fileName: fileName,
          initialDirectory: nmhDir
        );

        if (path != null) {
          File(path).writeAsString(manifestJson);
          return true;
        }

        return false;
      } else if (Platform.isWindows) {
        final String nmhName = await _getBinaryAssetPath();
        final Map<String, dynamic> manifest = _createManifestContent(browser, '$assetsPath/$nmhName');
        final String manifestJson = json.encode(manifest);
        
        String mozillaRegistryPath = "${data.registryPath}\\com.solidsoft.routine";
        final Pointer<HKEY> hKey = calloc<HKEY>();
        
        try {
          final int result = RegCreateKeyEx(
            HKEY_CURRENT_USER,
            TEXT(mozillaRegistryPath),
            0,
            nullptr,
            REG_OPEN_CREATE_OPTIONS.REG_OPTION_NON_VOLATILE,
            REG_SAM_FLAGS.KEY_WRITE,
            nullptr,
            hKey,
            nullptr,
          );
          
          if (result != WIN32_ERROR.ERROR_SUCCESS) {
            return false;
          }
          
          // Write the manifest path to the registry
          // First, create a temporary file with the manifest
          final tempDir = await getTemporaryDirectory();
          final manifestFile = File('${tempDir.path}\\routine_manifest.json');
          
          await manifestFile.writeAsString(manifestJson);
          
          if (await manifestFile.exists()) {
            final manifestPath = manifestFile.path;
            final Pointer<Utf16> manifestPathUtf16 = TEXT(manifestPath);
            
            final int setValueResult = RegSetValueEx(
              hKey.value,
              nullptr,  // Default value
              0,
              REG_VALUE_TYPE.REG_SZ,
              manifestPathUtf16.cast<Uint8>(),
              (manifestPath.length + 1) * 2,  // Include null terminator, *2 for UTF-16
            );
            
            if (setValueResult != WIN32_ERROR.ERROR_SUCCESS) {
              return false;
            }
            
            RegCloseKey(hKey.value);
            return true;
          } else {
            return false;
          }
        } finally {
          calloc.free(hKey);
        }
      }
      
      return false;
    } catch (e, st) {
      Util.report('Error installing NMH', e, st);
      return false;
    }
  }
  
  // Install browser extension
  Future<bool> installBrowserExtension(Browser browser) async {
    try {
      final data = browserData[browser]!;
      String extensionUrl = data.extensionUrl;

      if (Platform.isMacOS) {
        await Process.run('open', ['-a', data.appName, extensionUrl]);
        return true;
      } else if (Platform.isWindows) {
        await Process.run('start', [data.windowsCommand, extensionUrl], runInShell: true);
        return true;
      }

      return false;
    } catch (e, st) {
      Util.report('Error opening browser to install browser extension for $browser', e, st);
      return false;
    }
  }
  
  Future<void> init() async {
    logger.i("Browser Extension - Init");
    final prefs = await SharedPreferences.getInstance();
    final connectedBrowsers = prefs.getStringList(_connectedBrowsersKey);
    
    if (connectedBrowsers != null && connectedBrowsers.isNotEmpty) {
      for (final browserStr in connectedBrowsers) {
        try {
          final browser = Browser.values.firstWhere((b) => b.name == browserStr);
          await connectToBrowser(browser);
        } catch (e) {
          logger.w('Invalid browser type in preferences: $browserStr');
        }
      }
    }
  }

  String get assetsPath {
    if (Platform.isMacOS) {
      return Platform.resolvedExecutable
          .replaceAll('/MacOS/Routine', '/Frameworks/App.framework/Resources/flutter_assets/assets/extension');
    } else {
      final exePath = Platform.resolvedExecutable;
      final exeDir = exePath.substring(0, exePath.lastIndexOf('/'));
      return '$exeDir/data/flutter_assets/assets/extension';
    }
  }
  
  Future<int?> _readNmhPort(Browser browser) async {
    try {
      final String portFile = '$assetsPath/routine_nmh_${browser.name}_port';
      logger.i("Reading port file: $portFile");
      
      final file = File(portFile);
      if (await file.exists()) {
        final content = await file.readAsString();
        return int.tryParse(content.trim());
      } else {
        logger.w("Port file does not exist for $browser");
      }
    } catch (e, st) {
      Util.report('Error reading NMH port for $browser', e, st);
    }
    return null;
  }

  Future<void> connectToBrowser(Browser browser, {int retryCount = 0}) async {
  // Don't attempt reconnection if in cooldown
  if (StrictModeService.instance.isInExtensionCooldown) {
    logger.i('Not attempting to connect to $browser - in cooldown period');
    return;
  }

  try {
    final port = await _readNmhPort(browser);
    if (port == null) {
      logger.w('Could not read NMH port for $browser');
      return;
    }
    
    final socket = await Socket.connect('127.0.0.1', port);
    logger.i('Connected to NMH TCP server for $browser on port $port');
    
    final conn = BrowserConnection(socket: socket);
    _connections[browser] = conn;
    
    final prefs = await SharedPreferences.getInstance();
    final connectedBrowsers = prefs.getStringList(_connectedBrowsersKey) ?? [];
    if (!connectedBrowsers.contains(browser.name)) {
      connectedBrowsers.add(browser.name);
      await prefs.setStringList(_connectedBrowsersKey, connectedBrowsers);
    }

    _connectionStreamController.add(true);

    socket.listen(
      (List<int> data) {
        conn.buffer.addAll(data);
        
        while (conn.buffer.isNotEmpty) {
          if (conn.len == null) {
            if ((conn.buffer.length) >= 4) {
              // Read length prefix using Uint8List and ByteData
              final lengthBytes = Uint8List.fromList(conn.buffer.take(4).toList());
              conn.len = ByteData.view(lengthBytes.buffer).getUint32(0, Endian.little);
              conn.buffer = conn.buffer.sublist(4);
            } else {
              break;
            }
          }

          if (conn.len != null && conn.buffer.length >= conn.len!) {
            final messageBytes = conn.buffer.take(conn.len!).toList();
            conn.buffer = conn.buffer.sublist(conn.len!);
            conn.len = null;

            try {
              final String message = utf8.decode(messageBytes);
              final Map<String, dynamic> decoded = json.decode(message);
              logger.i('Received from NMH ($browser): $decoded');
            } catch (e, st) {
              Util.report('Error decoding NMH message from $browser', e, st);
            }
          } else {
            break;
          }
        }
      },
      onError: (error) {
        Util.report('NMH socket error for $browser', error, null);
        _connections.remove(browser);
        _attemptReconnection(browser, retryCount);
      },
      onDone: () {
        logger.i('Socket closed for $browser');
        _connections.remove(browser);
        _attemptReconnection(browser, retryCount);
      },
    );
  } on SocketException catch (e) {
    _connections.remove(browser);
    if (e.osError?.errorCode == 61) {
      logger.i('NMH service for $browser is not running. The app will continue without NMH features for this browser.');
    } else {
      logger.w('Socket connection error for $browser: ${e.message}. The app will continue without NMH features for this browser.');
    }
    _attemptReconnection(browser, retryCount);
  }
}

Future<void> _attemptReconnection(Browser browser, int retryCount) async {
  // Maximum number of retry attempts
  const maxRetries = 5;
  
  // Don't retry if we've hit the maximum or if we're in cooldown
  if (retryCount >= maxRetries || StrictModeService.instance.isInExtensionCooldown) {
    return;
  }
  
  // Exponential backoff: 2^retryCount seconds (1, 2, 4, 8, 16 seconds)
  final delay = pow(2, retryCount).toInt();
  logger.i('Attempting to reconnect to $browser in $delay seconds (attempt ${retryCount + 1}/$maxRetries)');
  
  await Future.delayed(Duration(seconds: delay));
  await connectToBrowser(browser, retryCount: retryCount + 1);
}

  Future<void> sendToBrowser(String action, Map<String, dynamic> data, {Browser? browser}) async {
    if (browser != null) {
      await _sendToBrowser(browser, action, data);
    } else {
      for (final browser in _connections.keys) {
        await _sendToBrowser(browser, action, data);
      }
    }
  }
  
  Future<void> _sendToBrowser(Browser browser, String action, Map<String, dynamic> data) async {
    try {
      final message = {
        'action': action,
        'data': data,
      };
      
      final String jsonMessage = json.encode(message);
      final List<int> messageBytes = utf8.encode(jsonMessage);

      final socket = _connections[browser]?.socket;

      if (socket != null) {
        socket.add(Uint8List.fromList([
          ...Uint32List.fromList([messageBytes.length]).buffer.asUint8List(),
          ...messageBytes,
        ]));
        await socket.flush();
      }
    } catch (e, st) {
      Util.report('Failed to send message to NMH for $browser', e, st);
    }
  }
  
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  
  bool isBrowser(String appName) {
    final lowerAppName = appName.toLowerCase();
    return browserData.keys.any((browser) => lowerAppName.contains(browser.name));
  }
  
  void dispose() {
    for (final conn in _connections.values) {
      conn.socket.close();
    }

    _connectionStreamController.close();
  }
}
