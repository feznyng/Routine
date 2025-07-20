import 'dart:typed_data';
import 'package:Routine/constants.dart';
import 'package:Routine/models/browser_connection.dart';
import 'package:flutter/foundation.dart';
import 'package:Routine/models/installed_app.dart';
import 'package:Routine/services/browser_config.dart';
import 'package:Routine/util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Directory, File, Platform, Process, ServerSocket, InternetAddress;
import 'dart:typed_data' show ByteData, Uint8List;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:async';
import 'package:Routine/setup.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Routine/channels/desktop_channel.dart';

typedef InstalledBrowser = ({Browser browser, InstalledApp app});

class BrowserService with ChangeNotifier {
  DateTime? _initialConnectionDeadline;
  DateTime? _extensionGracePeriodEnd;
  DateTime? _extensionCooldownEnd;
  static const int _extensionCooldownMinutes = 10;
  Timer? _gracePeriodTimer;
  
  static final BrowserService _instance = BrowserService._internal();
  final Map<Browser, BrowserConnection> _connections = {};
  final Set<Browser> _controllable = {};
  final Map<String, BrowserConnection> _pendingConnections = {};
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  final StreamController<bool> _gracePeriodExpirationController = StreamController<bool>.broadcast();
  static const String _connectedBrowsersKey = 'connected_browsers';
  
  factory BrowserService() {
    return _instance;
  }
  
  BrowserService._internal();
  
  static BrowserService get instance => _instance;
  
  Future<void> init() async {
    logger.i("Browser Extension - Init");
    _initialConnectionDeadline = DateTime.now().add(const Duration(seconds: 5));
    await startServer();

    if (Platform.isMacOS) {
      final browsers = await getInstalledSupportedBrowsers();
      for (final installedBrowser in browsers) {
        final browser = installedBrowser.browser;
        final data = browserData[installedBrowser.browser]!;
        if (data.macosControllable) {
          logger.i("checking if $browser is controllable");
          final controllable = await DesktopChannel.instance.hasAutomationPermission(data.macosPackage);
          logger.i("$browser is controllable = $controllable");
          if (controllable) {
            _controllable.add(browser);
          }
        }
      }
    }
    
    // Listen for browser controllability updates from native side
    if (Platform.isMacOS) {
      DesktopChannel.instance.browserControllabilityStream.listen((event) {
        final bundleId = event.bundleId;
        final isControllable = event.controllable;

        logger.i("Browser event = $bundleId, controllable = $isControllable");
        
        final browser = _getBrowserFromBundleId(bundleId);
        if (browser != null) {
          if (isControllable) {
            _controllable.add(browser);
            logger.i('Browser $browser is now controllable');
          } else {
            _controllable.remove(browser);
            logger.i('Browser $browser is no longer controllable');
          }

          _connectionStreamController.add(true);
          notifyListeners();
        }
      });
    }
  }
  
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  bool get isExtensionConnected => _connections.values.isNotEmpty;

  bool get isInitialConnectionPeriod {
    if (_initialConnectionDeadline == null) return false;
    return DateTime.now().isBefore(_initialConnectionDeadline!);
  }

  bool get isInGracePeriod {
    if (_extensionGracePeriodEnd == null) return false;
    return DateTime.now().isBefore(_extensionGracePeriodEnd!);
  }
  
  bool get isInCooldown {
    if (_extensionCooldownEnd == null) return false;
    return DateTime.now().isBefore(_extensionCooldownEnd!);
  }
  
  int get remainingGracePeriodSeconds {
    if (!isInGracePeriod) return 0;
    return _extensionGracePeriodEnd!.difference(DateTime.now()).inSeconds;
  }
  
  int get remainingCooldownMinutes {
    if (!isInCooldown) return 0;
    return _extensionCooldownEnd!.difference(DateTime.now()).inMinutes + 1; // +1 to round up
  }

  Future<bool> requestAutomationPermission(Browser browser, {bool openPrefsOnReject = false}) async {
    final data = browserData[browser]!;

    final result = await DesktopChannel.instance.requestAutomationPermission(data.macosPackage, openPrefsOnReject: openPrefsOnReject);

    if (result) {
      _controllable.add(browser);
    } else {
      _controllable.remove(browser);
    }

    return result;
  }

  Stream<bool> get gracePeriodStream => _gracePeriodExpirationController.stream;

  void startGracePeriod(int gracePeriodDuration) {
    if (isInCooldown) {
      return;
    }
    
    _extensionGracePeriodEnd = DateTime.now().add(Duration(seconds: gracePeriodDuration));
    
    notifyListeners();
    _gracePeriodExpirationController.add(true);

    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer(Duration(seconds: gracePeriodDuration), () {
      _endGracePeriod();
    });
  }

  bool endGracePeriod() {
    if (!isInGracePeriod) return false;
    _endGracePeriod();
    return true;
  }

  void _endGracePeriod() {
    _extensionGracePeriodEnd = null;
    _gracePeriodTimer?.cancel();
    _extensionGracePeriodEnd = null;
    _extensionCooldownEnd = DateTime.now().add(Duration(minutes: _extensionCooldownMinutes));
    
    _gracePeriodExpirationController.add(false);
    notifyListeners();
  }
  
  bool isBrowserConnected(Browser browser, {bool controlled = true}) {
    return _connections.containsKey(browser) || !controlled || _controllable.contains(browser);
  }

  BrowserData getBrowserData(Browser browser) {
    return browserData[browser]!;
  }
    
  Future<List<InstalledBrowser>> getInstalledSupportedBrowsers({bool? connected = false, bool controlled = true}) async {
    List<InstalledBrowser> browsers = await _getInstalledSupportedBrowsers();

    if (connected == true) {
      return browsers.where((b) => isBrowserConnected(b.browser, controlled: controlled)).toList();
    } else if (connected == false) {
      return browsers.where((b) => !isBrowserConnected(b.browser, controlled: controlled)).toList();
    }

    return browsers;
  }

  Future<List<InstalledBrowser>> _getInstalledSupportedBrowsers() async {
    List<InstalledBrowser> supportedBrowsers = [];
    
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
                supportedBrowsers.add((browser: browser, app: InstalledApp(filePath: entity.path, name: browser.name)));
              }
            }
          }
        }
      } else if (Platform.isWindows) {
        for (final entry in browserData.entries) {
          for (final path in entry.value.windowsPaths) {
            final dir = Directory(path);
            if (await dir.exists()) {
              supportedBrowsers.add((browser: entry.key, app: InstalledApp(filePath: path, name: entry.key.name)));

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
      return 'native_macos';
    } else if (Platform.isWindows) {
      return 'native_windows.exe';
    } else if (Platform.isLinux) {
      return 'native_linux';
    }
    throw UnsupportedError('Unsupported platform');
  }

  Map<String, dynamic> _createManifestContent(Browser browser, String binaryPath) {
    return {
      'name': kAppName,
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
        
        final Map<String, dynamic> manifest = _createManifestContent(browser, '$nmhPath/$nmhName');
        final String manifestJson = json.encode(manifest);

        final fileName = '$kAppName.json';
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
        final Map<String, dynamic> manifest = _createManifestContent(browser, '$nmhPath/$nmhName');
        final String manifestJson = json.encode(manifest);
        
        String mozillaRegistryPath = "${data.windowsRegistryPath}\\$kAppName";
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

  String get nmhPath {
    if (Platform.isMacOS) {
      return Platform.resolvedExecutable
          .replaceAll('/MacOS/Routine', '/Frameworks/App.framework/Resources/flutter_assets/assets/extension');
    } else {
      final exePath = Platform.resolvedExecutable;
      final exeDir = exePath.substring(0, exePath.lastIndexOf('/'));
      return '$exeDir/data/flutter_assets/assets/extension';
    }
  }

  ServerSocket? _server;

  Future<void> startServer() async {
    if (_server != null) return;

    try {
      ServerSocket? server;
      int? boundPort;
      
      for (int port = 54320; port <= 54330; port++) {
        try {
          server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
          boundPort = port;
          break;
        } catch (e) {
          logger.d('Port $port is not available');
        }
      }
      
      if (server == null || boundPort == null) {
        throw Exception('Could not find available port in range 54320-54330');
      }
      
      _server = server;
      final supportDir = await getApplicationSupportDirectory();
      await supportDir.create(recursive: true);
      
      final portFile = File(p.join(supportDir.path, 'routine_server_port'));
      await portFile.writeAsString(boundPort.toString());
      
      _server!.listen((socket) {
        logger.i('NMH connected from ${socket.remoteAddress.address}');

        final connection = BrowserConnection(socket: socket);
        final socketId = socket.remoteAddress.address;
        _pendingConnections[socketId] = connection;

        socket.listen(
          (data) async {
            await _handlePendingData(socketId, data);
          },
          onError: (error) {
            logger.e('Error from NMH socket: $error');
            _pendingConnections.remove(socketId);
          },
          onDone: () {
            logger.i('NMH socket closed');
            // Find and disconnect browser if it was moved to active connections
            final browser = _connections.entries.firstWhereOrNull((entry) => entry.value.socket == socket)?.key;
            if (browser != null) {
              _handleDisconnect(browser);
            } else {
              _pendingConnections.remove(socketId);
            }
          },
        );
      });
    } catch (e, st) {
      Util.report('Error starting TCP server', e, st);
    }
  }

  Future<void> _handlePendingData(String socketId, List<int> data) async {
    final connection = _pendingConnections[socketId];
    if (connection == null) {
      logger.w('No pending connection found for socket $socketId');
      return;
    }

    logger.d('Received ${data.length} bytes from socket $socketId');
    connection.buffer.addAll(data);
    
    while (connection.buffer.length >= 4) {
      if (connection.len == null) {
        connection.len = ByteData.view(Uint8List.fromList(connection.buffer.sublist(0, 4)).buffer).getUint32(0, Endian.little);
        connection.buffer.removeRange(0, 4);
        logger.d('Message length: ${connection.len} bytes');
      }

      if (connection.buffer.length >= connection.len!) {
        final message = utf8.decode(connection.buffer.sublist(0, connection.len!));
        logger.d('Decoded message from socket $socketId: $message');
        connection.buffer.removeRange(0, connection.len!);
        connection.len = null;

        try {
          final decoded = json.decode(message) as Map<String, dynamic>;
          await _handlePendingMessage(socketId, decoded);
        } catch (e, st) {
          logger.e('Error decoding message from NMH: $e');
          Util.report('Error decoding message from NMH', e, st);
        }
      } else {
        logger.d('Waiting for more data. Have ${connection.buffer.length} bytes, need ${connection.len}');
        break;
      }
    }
  }

  Future<void> _handlePendingMessage(String socketId, Map<String, dynamic> message) async {
    logger.i('Received message from pending NMH: $message');
    
    final action = message['action'] as String?;
    final data = message['data'] as Map<String, dynamic>?;
    
    if (action == 'browser_info' && data != null) {
      final browserName = data['browser'] as String?;
      if (browserName != null) {
        final browser = Browser.values.firstWhere(
          (b) => b.name.toLowerCase() == browserName.toLowerCase(),
          orElse: () => Browser.firefox
        );
        
        final connection = _pendingConnections.remove(socketId);
        if (connection != null) {
          _connections[browser] = connection;
          _connectionStreamController.add(true);
          await _saveBrowserConnection(browser);
        }
      }
    }
  }

  void _handleDisconnect(Browser browser) {
    if (_connections.remove(browser) != null) {
      _connectionStreamController.add(false);
    }
  }

  Future<void> _saveBrowserConnection(Browser browser) async {
    final prefs = await SharedPreferences.getInstance();
    final connectedBrowsers = prefs.getStringList(_connectedBrowsersKey) ?? [];
    if (!connectedBrowsers.contains(browser.name)) {
      connectedBrowsers.add(browser.name);
      await prefs.setStringList(_connectedBrowsersKey, connectedBrowsers);
    }
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
        final lengthBytes = Uint8List(4);
        final view = ByteData.view(lengthBytes.buffer);
        view.setUint32(0, messageBytes.length, Endian.little);
        
        socket.add(Uint8List.fromList([
          ...lengthBytes,
          ...messageBytes,
        ]));
        await socket.flush();
      }
    } catch (e, st) {
      Util.report('Failed to send message to NMH for $browser', e, st);
    }
  }
  
  @override
  void dispose() {
    super.dispose();

    for (final conn in _connections.values) {
      conn.socket.close();
    }
    _connections.clear();
    _server?.close();
    _server = null;
    _connectionStreamController.close();
  }
  
  // Helper method to map bundle IDs to Browser enum values
  Browser? _getBrowserFromBundleId(String bundleId) {
    switch (bundleId) {
      case 'com.google.Chrome':
        return Browser.chrome;
      case 'com.microsoft.edgemac':
        return Browser.edge;
      case 'com.apple.Safari':
        return Browser.safari;
      case 'com.operasoftware.Opera':
        return Browser.opera;
      case 'com.brave.Browser':
        return Browser.brave;
      case 'org.mozilla.firefox':
        return Browser.firefox;
      default:
        return null;
    }
  }
}
