import 'package:Routine/util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Directory, File, Platform, Process, ProcessResult, Socket, SocketException;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:win32/win32.dart';
import 'package:win32/src/constants.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:Routine/setup.dart';
import 'package:collection/src/iterable_extensions.dart';

enum Browser {
  firefox
}

class BrowserData {
  final int port;
  final List<String> windowsPaths;
  final String appName;
  final String windowsCommand;
  final String extensionUrl;
  final String macosNmhDir;
  final String registryPath;

  BrowserData({required this.port, required this.windowsPaths, required this.appName, required this.windowsCommand, required this.extensionUrl, required this.macosNmhDir, required this.registryPath});
}

class BrowserConnection {
  final Socket socket;
  List<int> buffer = [];
  int? len;

  BrowserConnection({required this.socket});
}

class BrowserExtensionService {
  static final BrowserExtensionService _instance = BrowserExtensionService._internal();
  
  final Map<Browser, BrowserData> _data = {
    Browser.firefox: BrowserData(
      port: 54322,
      windowsPaths: ['C:\\Program Files\\Mozilla Firefox', 'C:\\Program Files (x86)\\Mozilla Firefox'],
      windowsCommand: 'firefox',
      appName: 'Firefox',
      extensionUrl: 'https://addons.mozilla.org/firefox/addon/routineblocker/',
      macosNmhDir: 'Library/Application Support/Mozilla/NativeMessagingHosts/',
      registryPath: 'SOFTWARE\\Mozilla\\NativeMessagingHosts'
    )
  };
  final Map<Browser, BrowserConnection> _connections = {};
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  
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
    return _data[browser]!;
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
        for (final entry in _data.entries) {
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
      return arch == 'arm64' ? 'assets/extension/native_macos_arm64' : 'assets/extension/native_macos_x86_64';
    } else if (Platform.isWindows) {
      return 'assets/extension/native_windows.exe';
    } else if (Platform.isLinux) {
      return 'assets/extension/native_linux';
    }
    throw UnsupportedError('Unsupported platform');
  }

  Map<String, dynamic> _createManifestContent(String binaryPath) {
    return {
      'name': 'com.solidsoft.routine.NativeMessagingHost',
      'description': 'Routine Native Messaging Host',
      'path': binaryPath,
      'type': 'stdio',
      'allowed_extensions': ['blocker@routineblocker.com']
    };
  }

  Future<bool> installNativeMessagingHost(Browser browser) async {
    try {
      final data = _data[browser]!;

      if (Platform.isMacOS) {
        final String assetPath = await _getBinaryAssetPath();
        
        final String bundlePath = Platform.resolvedExecutable
            .replaceAll('/MacOS/Routine', '/Frameworks/App.framework/Resources/flutter_assets/$assetPath');
        
        final Map<String, dynamic> manifest = _createManifestContent(bundlePath);
        final String manifestJson = json.encode(manifest);

        final fileName = 'com.solidsoft.routine.NativeMessagingHost.json';
        final nmhDir = Platform.environment['HOME']! + data.macosNmhDir;

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
        final String assetPath = await _getBinaryAssetPath();
        final String bundlePath = Platform.resolvedExecutable
            .replaceAll('/MacOS/Routine', '/Frameworks/App.framework/Resources/flutter_assets/$assetPath');
        
        final Map<String, dynamic> manifest = _createManifestContent(bundlePath);
        final String manifestJson = json.encode(manifest);
        
        String mozillaRegistryPath = "${data.registryPath}\\com.solidsoft.routine.NativeMessagingHost";
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
              REG_SZ,
              manifestPathUtf16.cast<Uint8>(),
              (manifestPath.length + 1) * 2,  // Include null terminator, *2 for UTF-16
            );
            
            if (setValueResult != ERROR_SUCCESS) {
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
      final data = _data[browser]!;
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
    // TODO: switch this to only attempt to reconnect to previously connected browser
    for (final browser in _data.keys) {
      await connectToNMH(browser);
    }
  }
  
  Future<void> connectToNMH(Browser browser) async {
    try {
      final data = _data[browser]!;
      
      // Connect to the NMH for this browser
      final socket = await Socket.connect('127.0.0.1', data.port);
      logger.i('Connected to NMH TCP server for $browser on port ${data.port}');
      
      final conn = BrowserConnection(socket: socket);
      _connections[browser] = conn;
      
      // TODO: persist browser type to shared prefs

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
        },
        onDone: () {
          logger.i('Socket closed for $browser');
          _connections.remove(browser);
        },
      );
    } on SocketException catch (e) {
      _connections.remove(browser);
      if (e.osError?.errorCode == 61) {
        logger.i('NMH service for $browser is not running. The app will continue without NMH features for this browser.');
      } else {
        logger.w('Socket connection error for $browser: ${e.message}. The app will continue without NMH features for this browser.');
      }
    }
  }
  
  Future<void> sendToNMH(String action, Map<String, dynamic> data, {Browser? browser}) async {
    if (browser != null) {
      await _sendToSpecificBrowser(browser, action, data);
    } else {
      for (final browser in _connections.keys) {
        await _sendToSpecificBrowser(browser, action, data);
      }
    }
  }
  
  Future<void> _sendToSpecificBrowser(Browser browser, String action, Map<String, dynamic> data) async {
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
    return _data.keys.any((browser) => lowerAppName.contains(browser.name));
  }
  
  void dispose() {
    for (final conn in _connections.values) {
      conn.socket.close();
    }

    _connectionStreamController.close();
  }
}
