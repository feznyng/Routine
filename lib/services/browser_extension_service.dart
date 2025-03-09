import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Directory, File, Platform, Process, Socket, SocketException;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:win32/win32.dart';
import 'package:win32/src/constants.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:typed_data';
import 'dart:async';

class BrowserExtensionService {
  // Singleton instance
  static final BrowserExtensionService _instance = BrowserExtensionService._internal();
  
  // Platform channel for native methods
  static const MethodChannel _channel = MethodChannel('com.routine.applist');
  
  // Socket connection to Native Messaging Host
  Socket? _socket;
  List<int> _messageBuffer = [];
  int? _expectedLength;
  
  // Flag to track browser extension connection status
  // Since the extension starts the NMH, this also indicates if NMH is connected
  bool _extensionConnected = false;
  
  // Set of browser names in lowercase for O(1) lookup
  final Set<String> _browserNames = {
    'firefox'
  };
  
  // List of listeners for extension connection status changes
  final List<Function(bool)> _connectionListeners = [];
  
  // Stream controller for extension connection status changes
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  
  factory BrowserExtensionService() {
    return _instance;
  }
  
  BrowserExtensionService._internal();
  
  static BrowserExtensionService get instance => _instance;
  
  // Get current extension connection status
  // Since the extension starts the NMH, this also indicates if NMH is connected
  bool get isExtensionConnected => _extensionConnected;
  
  // Launch the browser extension onboarding process
  Future<void> launchOnboardingProcess() async {
    await connectToNMH();
  }
  
  // Get a list of installed browsers that are supported
  Future<List<String>> getInstalledSupportedBrowsers() async {
    List<String> supportedBrowsers = [];
    
    try {
      if (Platform.isMacOS) {
        // Check for Firefox in Applications folder
        final Directory appDir = Directory('/Applications');
        if (await appDir.exists()) {
          final entities = await appDir.list().toList();
          for (var entity in entities) {
            if (entity is Directory && entity.path.toLowerCase().contains('firefox') && entity.path.endsWith('.app')) {
              supportedBrowsers.add(entity.path);
              break;
            }
          }
        }
      } else if (Platform.isWindows) {
        // Check for Firefox in Program Files
        final List<String> possiblePaths = [
          'C:\\Program Files\\Mozilla Firefox',
          'C:\\Program Files (x86)\\Mozilla Firefox',
        ];
        
        for (var path in possiblePaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            supportedBrowsers.add(path);
            break;
          }
        }
      } else if (Platform.isLinux) {
        // Check if Firefox is installed using 'which'
        final result = await Process.run('which', ['firefox']);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          supportedBrowsers.add(result.stdout.toString().trim());
        }
      }
    } catch (e) {
      debugPrint('Error detecting browsers: $e');
    }
    
    return supportedBrowsers;
  }
  
  // Install native messaging host manifest
  Future<bool> installNativeMessagingHost() async {
    try {
      // Create the manifest file with the correct path to the native messaging host
      // and install it in the correct location based on the platform
      
      if (Platform.isMacOS) {
        // On macOS, we need to use NSOpenPanel to save the file due to sandbox restrictions
        // Create the manifest content
        final Map<String, dynamic> manifest = {
          'name': 'com.routine.native_messaging',
          'description': 'Routine Native Messaging Host',
          'path': '/Users/ajan/Projects/routine/target/debug/native',
          'type': 'stdio',
          'allowed_extensions': ['blocker@routine-blocker.com']
        };
        
        final String manifestJson = json.encode(manifest);
        
        try {
          // Call the platform method to show NSOpenPanel and save the file
          final bool result = await _channel.invokeMethod('saveNativeMessagingHostManifest', {
            'content': manifestJson,
          });
          
          return result;
        } catch (e) {
          return false;
        }
      } else if (Platform.isWindows) {
        // On Windows, the manifest goes in the registry
        // Use win32 package to write to the registry
        
        // Get the path to the native messaging host executable
        final Directory appDir = await getApplicationSupportDirectory();
        final String nmhPath = '${appDir.path}\\routine-nmh.exe';
        
        // Create the manifest content
        final Map<String, dynamic> manifest = {
          'name': 'com.routine.nmh',
          'description': 'Routine Native Messaging Host',
          'path': nmhPath,
          'type': 'stdio',
          'allowed_extensions': ['routine@example.com']
        };
        
        // Convert manifest to JSON string
        final String manifestJson = json.encode(manifest);
        
        // Registry paths for Firefox
        const String mozillaRegistryPath = 
            'SOFTWARE\\Mozilla\\NativeMessagingHosts\\com.routine.nmh';
            
        // Open the registry key (create if it doesn't exist)
        final Pointer<HKEY> hKey = calloc<HKEY>();
        
        try {
          // Create or open the key
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
            
            // Close the registry key
            RegCloseKey(hKey.value);
            return true;
          } else {
            return false;
          }
        } finally {
          // Free allocated memory
          calloc.free(hKey);
        }
      } else if (Platform.isLinux) {
        // On Linux, the manifest goes in ~/.mozilla/native-messaging-hosts/
        final String homeDir = Platform.environment['HOME'] ?? '';
        final String manifestDir = '$homeDir/.mozilla/native-messaging-hosts';
        
        // Create directories if they don't exist
        final Directory dir = Directory(manifestDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        
        // Create the manifest file
        final File manifestFile = File('$manifestDir/com.routine.native_messaging.json');
        
        // Example manifest content
        final Map<String, dynamic> manifest = {
          'name': 'com.routine.nmh',
          'description': 'Routine Native Messaging Host',
          'path': '/usr/local/bin/routine-nmh',
          'type': 'stdio',
          'allowed_extensions': ['routine@example.com']
        };
        
        await manifestFile.writeAsString(json.encode(manifest));
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Install browser extension
  Future<bool> installBrowserExtension(String browserName) async {
    try {
      // This is a placeholder for the actual implementation
      // In a real implementation, this would open the browser with the extension URL
      
      if (browserName.toLowerCase().contains('firefox')) {
        // Firefox extension URL (this would be your actual extension URL)        
        if (Platform.isMacOS) {
          await Process.run('open', ['-a', 'Firefox']);
          return true;
        } else if (Platform.isWindows) {
          await Process.run('start', ['firefox'], runInShell: true);
          return true;
        } else if (Platform.isLinux) {
          await Process.run('firefox', []);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error installing browser extension: $e');
      return false;
    }
  }
  
  // Initialize the browser extension service
  Future<void> init() async {
    await connectToNMH();
  }
  
  // Connect to the Native Messaging Host
  Future<void> connectToNMH() async {
    try {
      _socket = await Socket.connect('127.0.0.1', 54322);
      debugPrint('Connected to NMH TCP server');

      setExtensionConnected(true);

      _socket?.listen(
        (List<int> data) {
          _messageBuffer.addAll(data);
          
          while (_messageBuffer.isNotEmpty) {
            if (_expectedLength == null) {
              if (_messageBuffer.length >= 4) {
                // Read length prefix using Uint8List and ByteData
                final lengthBytes = Uint8List.fromList(_messageBuffer.take(4).toList());
                _expectedLength = ByteData.view(lengthBytes.buffer).getUint32(0, Endian.little);
                _messageBuffer = _messageBuffer.sublist(4);
              } else {
                break;
              }
            }

            if (_expectedLength != null && _messageBuffer.length >= _expectedLength!) {

              final messageBytes = _messageBuffer.take(_expectedLength!).toList();
              _messageBuffer = _messageBuffer.sublist(_expectedLength!);
              _expectedLength = null;

              try {
                final String message = utf8.decode(messageBytes);
                final Map<String, dynamic> decoded = json.decode(message);
                debugPrint('Received from NMH: $decoded');
              } catch (e) {
                debugPrint('Error decoding message: $e');
              }
            } else {
              break;
            }
          }
        },
        onError: (error) {
          debugPrint('Socket error: $error');
          setExtensionConnected(false);
        },
        onDone: () {
          debugPrint('Socket closed');
          setExtensionConnected(false);
        },
      );
    } on SocketException catch (e) {
      setExtensionConnected(false);
      if (e.osError?.errorCode == 61) {
        debugPrint('NMH service is not running. The app will continue without NMH features.');
      } else {
        debugPrint('Socket connection error: ${e.message}. The app will continue without NMH features.');
      }
    }
  }
  
  // Send a message to the Native Messaging Host
  Future<void> sendToNMH(String action, Map<String, dynamic> data) async {
     if (!isExtensionConnected) {
      await connectToNMH();
      if (!isExtensionConnected) {
        debugPrint('Failed to connect to NMH, skipping update');
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
      _socket?.add(Uint8List.fromList([
        ...Uint32List.fromList([messageBytes.length]).buffer.asUint8List(),
        ...messageBytes,
      ]));
      await _socket?.flush();
    } catch (e) {
      debugPrint('Failed to send message to NMH: $e');
    }
  }

  void setExtensionConnected(bool connected) {
    if (_extensionConnected != connected) {
      _extensionConnected = connected;
      
      for (final listener in _connectionListeners) {
        listener(_extensionConnected);
      }
      
      _connectionStreamController.add(_extensionConnected);
    }
  }
  
  void addConnectionListener(Function(bool) listener) {
    if (!_connectionListeners.contains(listener)) {
      _connectionListeners.add(listener);
    }
  }
  
  void removeConnectionListener(Function(bool) listener) {
    _connectionListeners.remove(listener);
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
    _socket?.close();
    _connectionListeners.clear();
    _connectionStreamController.close();
  }
}
