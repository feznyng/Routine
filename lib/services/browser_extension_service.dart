import 'package:Routine/util.dart';
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

class BrowserExtensionService {
  // Singleton instance
  static final BrowserExtensionService _instance = BrowserExtensionService._internal();
  
  // Platform channel for native methods
  static const MethodChannel _channel = MethodChannel('com.solidsoft.routine');
  
  // Socket connections to Native Messaging Host for multiple browsers
  final Map<String, Socket> _browserSockets = {};
  final Map<String, List<int>> _messageBuffers = {};
  final Map<String, int?> _expectedLengths = {};
  
  // Track connection status for each browser
  final Map<String, bool> _browserConnectionStatus = {};
  
  // Flag to track if any browser extension is connected
  bool _anyExtensionConnected = false;
  
  // Set of supported browser names
  final Set<String> _browserNames = {
    'firefox',
    'chrome',
    'edge',
    'brave',
    'opera'
  };
  
  // Stream controller for extension connection status changes
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  
  factory BrowserExtensionService() {
    return _instance;
  }
  
  BrowserExtensionService._internal();
  
  static BrowserExtensionService get instance => _instance;
  
  // Get current extension connection status for any browser
  bool get isExtensionConnected => _anyExtensionConnected;
  
  // Get connection status for a specific browser
  bool isBrowserConnected(String browserName) {
    return _browserConnectionStatus[browserName.toLowerCase()] ?? false;
  }
  
  // Get list of connected browsers
  List<String> get connectedBrowsers {
    return _browserConnectionStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
  
  // Launch the browser extension onboarding process
  Future<void> launchOnboardingProcess() async {
    await connectToAllBrowsers();
  }
  
  // Get a list of installed browsers that are supported
  Future<List<String>> getInstalledSupportedBrowsers() async {
    List<String> supportedBrowsers = [];
    
    try {
      if (Platform.isMacOS) {
        // Check for supported browsers in Applications folder
        final Directory appDir = Directory('/Applications');
        if (await appDir.exists()) {
          final entities = await appDir.list().toList();
          for (var entity in entities) {
            if (entity is Directory && entity.path.endsWith('.app')) {
              final lowerPath = entity.path.toLowerCase();
              
              // Check for each supported browser
              if (lowerPath.contains('firefox')) {
                supportedBrowsers.add('Firefox');
              } else if (lowerPath.contains('chrome') && !lowerPath.contains('chromium')) {
                supportedBrowsers.add('Chrome');
              } else if (lowerPath.contains('edge')) {
                supportedBrowsers.add('Edge');
              } else if (lowerPath.contains('brave')) {
                supportedBrowsers.add('Brave');
              } else if (lowerPath.contains('opera')) {
                supportedBrowsers.add('Opera');
              }
            }
          }
        }
      } else if (Platform.isWindows) {
        // Check for supported browsers in Program Files
        final List<Map<String, dynamic>> possibleBrowsers = [
          {'name': 'Firefox', 'paths': ['C:\\Program Files\\Mozilla Firefox', 'C:\\Program Files (x86)\\Mozilla Firefox']},
          {'name': 'Chrome', 'paths': ['C:\\Program Files\\Google\\Chrome\\Application', 'C:\\Program Files (x86)\\Google\\Chrome\\Application']},
          {'name': 'Edge', 'paths': ['C:\\Program Files\\Microsoft\\Edge\\Application', 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application']},
          {'name': 'Brave', 'paths': ['C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application', 'C:\\Program Files (x86)\\BraveSoftware\\Brave-Browser\\Application']},
          {'name': 'Opera', 'paths': ['C:\\Program Files\\Opera', 'C:\\Program Files (x86)\\Opera']}
        ];
        
        for (var browser in possibleBrowsers) {
          for (var path in browser['paths']!) {
            final dir = Directory(path);
            if (await dir.exists()) {
              supportedBrowsers.add(browser['name']!);
              break;
            }
          }
        }
      } else if (Platform.isLinux) {
        // Check if supported browsers are installed using 'which'
        final List<String> browserCommands = ['firefox', 'google-chrome', 'microsoft-edge', 'brave-browser', 'opera'];
        
        for (var command in browserCommands) {
          final result = await Process.run('which', [command]);
          if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
            String browserName;
            if (command == 'firefox') {
              browserName = 'Firefox';
            } else if (command == 'google-chrome') {
              browserName = 'Chrome';
            } else if (command == 'microsoft-edge') {
              browserName = 'Edge';
            } else if (command == 'brave-browser') {
              browserName = 'Brave';
            } else if (command == 'opera') {
              browserName = 'Opera';
            } else {
              continue;
            }
            supportedBrowsers.add(browserName);
          }
        }
      }
    } catch (e, st) {
      Util.report('Error detecting browsers', e, st);
    }
    
    return supportedBrowsers;
  }
  
  // Check if the native messaging host binary is installed
  Future<bool> isNativeMessagingHostBinaryInstalled() async {
    try {
      final Directory appDir = await getApplicationSupportDirectory();
      String nmhPath;
      
      if (Platform.isMacOS) {
        nmhPath = '${appDir.path}/routine-nmh';
      } else if (Platform.isWindows) {
        nmhPath = '${appDir.path}\\routine-nmh.exe';
      } else if (Platform.isLinux) {
        nmhPath = '${appDir.path}/routine-nmh';
      } else {
        return false;
      }
      
      final File nmhFile = File(nmhPath);
      return await nmhFile.exists();
    } catch (e, st) {
      Util.report('Error checking for NMH', e, st);
      return false;
    }
  }
  
  // Helper function to get the appropriate binary asset path for the current platform
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

  // Helper function to get the target binary path (used for Windows)
  Future<String> _getTargetBinaryPath() async {
    final Directory appDir = await getApplicationSupportDirectory();
    if (Platform.isWindows) {
      return '${appDir.path}\\routine-nmh.exe';
    } else {
      return '${appDir.path}/routine-nmh';
    }
  }

  // Helper function to create manifest content
  Map<String, dynamic> _createManifestContent(String binaryPath) {
    return {
      'name': 'com.solidsoft.routine.NativeMessagingHost',
      'description': 'Routine Native Messaging Host',
      'path': binaryPath,
      'type': 'stdio',
      'allowed_extensions': ['blocker@routineblocker.com']
    };
  }

  // Install native messaging host
  Future<bool> installNativeMessagingHost() async {
    try {
      if (Platform.isMacOS) {
        final String assetPath = await _getBinaryAssetPath();
        
        final String bundlePath = Platform.resolvedExecutable
            .replaceAll('/MacOS/Routine', '/Frameworks/App.framework/Resources/flutter_assets/$assetPath');
        
        final Map<String, dynamic> manifest = _createManifestContent(bundlePath);
        final String manifestJson = json.encode(manifest);
        
        try {
          final bool result = await _channel.invokeMethod('saveNativeMessagingHostManifest', {
            'content': manifestJson
          });
          
          if (result) {
            Timer(const Duration(seconds: 2), () => connectToNMH());
            return true;
          } else {
            return false;
          }
        } catch (e) {
          return false;
        }
      } else if (Platform.isWindows) {
        final String nmhPath = await _getTargetBinaryPath();
        
        final Map<String, dynamic> manifest = _createManifestContent(nmhPath);
        final String manifestJson = json.encode(manifest);
        
        const String mozillaRegistryPath = 
            'SOFTWARE\\Mozilla\\NativeMessagingHosts\\com.solidsoft.routine.NativeMessagingHost';
            
        final Pointer<HKEY> hKey = calloc<HKEY>();
        
        try {
          final int result = RegCreateKeyEx(
            HKEY_CURRENT_USER,
            TEXT(mozillaRegistryPath),
            0,
            nullptr,
            REG_OPEN_CREATE_OPTIONS.REG_OPTION_NON_VOLATILE,
            KEY_WRITE,
            nullptr,
            hKey,
            nullptr,
          );
          
          if (result != ERROR_SUCCESS) {
            return false;
          }
          
          // Write the manifest path to the registry
          // First, create a temporary file with the manifest
          final tempDir = await getTemporaryDirectory();
          final manifestFile = File('${tempDir.path}\\routine_manifest.json');
          
          await manifestFile.writeAsString(manifestJson);
          
          // Check if file was created successfully
          if (await manifestFile.exists()) {
            // Set the default value to the path of the manifest file
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
      } else if (Platform.isLinux) {
        // On Linux, the manifest goes in ~/.mozilla/native-messaging-hosts/
        final String homeDir = Platform.environment['HOME'] ?? '';
        final String manifestDir = '$homeDir/.mozilla/native-messaging-hosts';
        
        // Get the path to the native messaging host executable
        final Directory appDir = await getApplicationSupportDirectory();
        final String nmhPath = '${appDir.path}/routine-nmh';
        
        // Create directories if they don't exist
        final Directory dir = Directory(manifestDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        // Create the manifest file
        final File manifestFile = File('$manifestDir/com.solidsoft.routine.NativeMessagingHost.json');
        
        // Example manifest content
        final Map<String, dynamic> manifest = {
          'name': 'com.routine.native_messaging',
          'description': 'Routine Native Messaging Host',
          'path': nmhPath,
          'type': 'stdio',
          'allowed_extensions': ['routine@example.com']
        };
        
        final String manifestJson = json.encode(manifest);
        
        await manifestFile.writeAsString(manifestJson);
        
        final bool exists = await manifestFile.exists();
        return exists;
      }
      
      return false;
    } catch (e, st) {
      Util.report('Error installing NMH', e, st);
      return false;
    }
  }
  
  // Install browser extension
  Future<bool> installBrowserExtension(String browserName) async {
    try {
      final browser = browserName.toLowerCase();
      String extensionUrl = '';
      
      // Set the appropriate extension URL based on the browser
      if (browser.contains('firefox')) {
        extensionUrl = 'https://addons.mozilla.org/firefox/addon/routineblocker/';
      } else if (browser.contains('chrome')) {
        extensionUrl = 'https://chrome.google.com/webstore/detail/routineblocker/extension-id';
      } else if (browser.contains('edge')) {
        extensionUrl = 'https://microsoftedge.microsoft.com/addons/detail/routineblocker/extension-id';
      } else if (browser.contains('brave')) {
        // Brave uses Chrome Web Store
        extensionUrl = 'https://chrome.google.com/webstore/detail/routineblocker/extension-id';
      } else if (browser.contains('opera')) {
        extensionUrl = 'https://addons.opera.com/extensions/details/routineblocker/';
      } else {
        logger.w('Unsupported browser: $browserName');
        return false;
      }
      
      // Open the browser with the extension URL
      if (Platform.isMacOS) {
        await Process.run('open', ['-a', browserName, extensionUrl]);
        return true;
      } else if (Platform.isWindows) {
        if (browser.contains('firefox')) {
          await Process.run('start', ['firefox', extensionUrl], runInShell: true);
        } else if (browser.contains('chrome')) {
          await Process.run('start', ['chrome', extensionUrl], runInShell: true);
        } else if (browser.contains('edge')) {
          await Process.run('start', ['msedge', extensionUrl], runInShell: true);
        } else if (browser.contains('brave')) {
          await Process.run('start', ['brave', extensionUrl], runInShell: true);
        } else if (browser.contains('opera')) {
          await Process.run('start', ['opera', extensionUrl], runInShell: true);
        }
        return true;
      } else if (Platform.isLinux) {
        if (browser.contains('firefox')) {
          await Process.run('firefox', [extensionUrl]);
        } else if (browser.contains('chrome')) {
          await Process.run('google-chrome', [extensionUrl]);
        } else if (browser.contains('edge')) {
          await Process.run('microsoft-edge', [extensionUrl]);
        } else if (browser.contains('brave')) {
          await Process.run('brave-browser', [extensionUrl]);
        } else if (browser.contains('opera')) {
          await Process.run('opera', [extensionUrl]);
        }
        return true;
      }
      
      return false;
    } catch (e, st) {
      Util.report('Error opening browser to install browser extension for $browserName', e, st);
      return false;
    }
  }
  
  // Initialize the browser extension service
  Future<void> init() async {
    await connectToAllBrowsers();
  }
  
  // Connect to the Native Messaging Host for a specific browser
  Future<void> connectToNMH({String browserName = 'default'}) async {
    final browser = browserName.toLowerCase();
    
    try {
      // Use different ports for different browsers
      // Base port is 54322, and we'll use offsets for different browsers
      int port = 54322;
      if (browser != 'default') {
        if (browser.contains('firefox')) {
          port = 54322;
        } else if (browser.contains('chrome')) {
          port = 54323;
        } else if (browser.contains('edge')) {
          port = 54324;
        } else if (browser.contains('brave')) {
          port = 54325;
        } else if (browser.contains('opera')) {
          port = 54326;
        }
      }
      
      // Initialize message buffer for this browser if not exists
      if (!_messageBuffers.containsKey(browser)) {
        _messageBuffers[browser] = [];
      }
      
      // Initialize expected length for this browser if not exists
      if (!_expectedLengths.containsKey(browser)) {
        _expectedLengths[browser] = null;
      }
      
      // Connect to the NMH for this browser
      final socket = await Socket.connect('127.0.0.1', port);
      logger.i('Connected to NMH TCP server for $browser on port $port');
      
      // Store the socket for this browser
      _browserSockets[browser] = socket;
      
      // Update connection status for this browser
      setBrowserConnected(browser, true);
      
      // Listen for messages from this browser's NMH
      socket.listen(
        (List<int> data) {
          _messageBuffers[browser]?.addAll(data);
          
          while (_messageBuffers[browser]?.isNotEmpty ?? false) {
            if (_expectedLengths[browser] == null) {
              if ((_messageBuffers[browser]?.length ?? 0) >= 4) {
                // Read length prefix using Uint8List and ByteData
                final lengthBytes = Uint8List.fromList(_messageBuffers[browser]!.take(4).toList());
                _expectedLengths[browser] = ByteData.view(lengthBytes.buffer).getUint32(0, Endian.little);
                _messageBuffers[browser] = _messageBuffers[browser]!.sublist(4);
              } else {
                break;
              }
            }

            if (_expectedLengths[browser] != null && 
                (_messageBuffers[browser]?.length ?? 0) >= _expectedLengths[browser]!) {

              final messageBytes = _messageBuffers[browser]!.take(_expectedLengths[browser]!).toList();
              _messageBuffers[browser] = _messageBuffers[browser]!.sublist(_expectedLengths[browser]!);
              _expectedLengths[browser] = null;

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
          setBrowserConnected(browser, false);
        },
        onDone: () {
          logger.i('Socket closed for $browser');
          setBrowserConnected(browser, false);
        },
      );
    } on SocketException catch (e) {
      setBrowserConnected(browser, false);
      if (e.osError?.errorCode == 61) {
        logger.i('NMH service for $browser is not running. The app will continue without NMH features for this browser.');
      } else {
        logger.w('Socket connection error for $browser: ${e.message}. The app will continue without NMH features for this browser.');
      }
    }
  }
  
  // Try to connect to all supported browsers
  Future<void> connectToAllBrowsers() async {
    for (final browser in _browserNames) {
      await connectToNMH(browserName: browser);
    }
  }
  
  // Send a message to the Native Messaging Host for a specific browser
  Future<void> sendToNMH(String action, Map<String, dynamic> data, {String? browserName}) async {
    // If browser is specified, send to that browser only
    if (browserName != null) {
      final browser = browserName.toLowerCase();
      await _sendToSpecificBrowser(browser, action, data);
      return;
    }
    
    // If no browser is specified, send to all connected browsers
    if (_browserSockets.isEmpty) {
      await connectToAllBrowsers();
      if (_browserSockets.isEmpty) {
        logger.w('Failed to connect to any NMH, skipping update');
        return;
      }
    }
    
    // Send to all connected browsers
    for (final browser in _browserSockets.keys) {
      await _sendToSpecificBrowser(browser, action, data);
    }
  }
  
  // Helper method to send to a specific browser
  Future<void> _sendToSpecificBrowser(String browser, String action, Map<String, dynamic> data) async {
    if (!(_browserConnectionStatus[browser] ?? false)) {
      await connectToNMH(browserName: browser);
      if (!(_browserConnectionStatus[browser] ?? false)) {
        logger.w('Failed to connect to NMH for $browser, skipping update');
        return;
      }
    }
    
    try {
      final message = {
        'action': action,
        'data': data,
      };
      
      final String jsonMessage = json.encode(message);
      final List<int> messageBytes = utf8.encode(jsonMessage);
      
      // Send length prefix followed by message
      _browserSockets[browser]?.add(Uint8List.fromList([
        ...Uint32List.fromList([messageBytes.length]).buffer.asUint8List(),
        ...messageBytes,
      ]));
      await _browserSockets[browser]?.flush();
    } catch (e, st) {
      Util.report('Failed to send message to NMH for $browser', e, st);
    }
  }

  // Update connection status for a specific browser
  void setBrowserConnected(String browserName, bool connected) {
    final browser = browserName.toLowerCase();
    
    if ((_browserConnectionStatus[browser] ?? false) != connected) {
      _browserConnectionStatus[browser] = connected;
      
      // Update the overall connection status
      _updateOverallConnectionStatus();
      
      // Notify listeners with the browser name and connection status
      _connectionStreamController.add(_anyExtensionConnected);
    }
  }
  
  // Update the overall connection status based on individual browser statuses
  void _updateOverallConnectionStatus() {
    final wasConnected = _anyExtensionConnected;
    _anyExtensionConnected = _browserConnectionStatus.values.any((connected) => connected);
    
    // If overall status changed, log it
    if (wasConnected != _anyExtensionConnected) {
      logger.i('Overall extension connection status changed to: $_anyExtensionConnected');
    }
  }
  
  // Get a stream of extension connection status changes
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  
  // Check if a given app name is a browser
  bool isBrowser(String appName) {
    final lowerAppName = appName.toLowerCase();
    return _browserNames.any((browser) => lowerAppName.contains(browser));
  }
  
  // Clean up resources
  void dispose() {
    // Close all browser sockets
    for (final socket in _browserSockets.values) {
      socket.close();
    }
    _browserSockets.clear();
    
    // Clear all buffers and statuses
    _messageBuffers.clear();
    _expectedLengths.clear();
    _browserConnectionStatus.clear();
    
    // Close the stream controller
    _connectionStreamController.close();
  }
}
