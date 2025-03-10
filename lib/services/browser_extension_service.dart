import 'package:flutter/material.dart';
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
    } catch (e) {
      debugPrint('Error checking if NMH binary is installed: $e');
      return false;
    }
  }
  
  // Install the native messaging host binary from assets
  Future<bool> installNativeMessagingHostBinary() async {
    try {
      // Get the application support directory
      final Directory appDir = await getApplicationSupportDirectory();
      String assetPath;
      String targetPath;
      
      debugPrint('Application support directory: ${appDir.path}');
      
      if (Platform.isMacOS) {
        // Determine which binary to use based on architecture
        final ProcessResult result = await Process.run('uname', ['-m']);
        final String arch = result.stdout.toString().trim();
        debugPrint('Detected architecture: $arch');
        
        if (arch == 'arm64') {
          assetPath = 'assets/extension/native_macos_arm64';
        } else {
          assetPath = 'assets/extension/native_macos_x86_64';
        }
        
        targetPath = '${appDir.path}/routine-nmh';
      } else if (Platform.isWindows) {
        // Windows binary would be here
        assetPath = 'assets/extension/native_windows.exe';
        targetPath = '${appDir.path}\\routine-nmh.exe';
        debugPrint('Native messaging host binary path: $targetPath');
        return false; // Not implemented yet
      } else if (Platform.isLinux) {
        // Linux binary would be here
        assetPath = 'assets/extension/native_linux';
        targetPath = '${appDir.path}/routine-nmh';
        debugPrint('Native messaging host binary path: $targetPath');
        return false; // Not implemented yet
      } else {
        return false;
      }
      
      debugPrint('Using asset: $assetPath');
      debugPrint('Installing binary to: $targetPath');
      
      // Load the binary from assets
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      debugPrint('Binary size: ${bytes.length} bytes');
      
      // Write the binary to the target path
      final File targetFile = File(targetPath);
      await targetFile.writeAsBytes(bytes);
      
      // Make the binary executable
      if (Platform.isMacOS || Platform.isLinux) {
        await Process.run('chmod', ['+x', targetPath]);
        debugPrint('Made binary executable with chmod +x');
      }
      
      final bool exists = await targetFile.exists();
      debugPrint('Binary installation in app directory ${exists ? "successful" : "failed"}');
      
      // Note: For macOS, the binary will be copied to the same directory as the manifest
      // during the manifest installation process via platform method
      return exists;
    } catch (e) {
      debugPrint('Error installing NMH binary: $e');
      return false;
    }
  }

  // Install native messaging host manifest
  Future<bool> installNativeMessagingHost() async {
    try {
      // Create the manifest file with the correct path to the native messaging host
      // and install it in the correct location based on the platform
      
      if (Platform.isMacOS) {
        // Determine which binary to use based on architecture
        String assetPath;
        final ProcessResult result = await Process.run('uname', ['-m']);
        final String arch = result.stdout.toString().trim();
        debugPrint('Detected architecture: $arch');
        
        if (arch == 'arm64') {
          assetPath = 'assets/extension/native_macos_arm64';
        } else {
          assetPath = 'assets/extension/native_macos_x86_64';
        }
        
        // Load the binary directly from assets
        debugPrint('Loading binary from asset: $assetPath');
        final ByteData data = await rootBundle.load(assetPath);
        final List<int> binaryBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        debugPrint('Read binary from assets, size: ${binaryBytes.length} bytes');
        
        // For macOS, the binary needs to be in the same directory as the manifest
        // which is outside the sandbox. The path in the manifest will be updated by
        // the platform method to point to the correct location.
        
        // Create the manifest content with a placeholder path that will be updated
        // by the platform method
        final Map<String, dynamic> manifest = {
          'name': 'com.routine.native_messaging',
          'description': 'Routine Native Messaging Host',
          'path': 'PLACEHOLDER_PATH', // This will be updated by the platform method
          'type': 'stdio',
          'allowed_extensions': ['blocker@routine-blocker.com']
        };
        
        final String manifestJson = json.encode(manifest);
        debugPrint('Manifest content (with placeholder path): $manifestJson');
        
        try {
          // Call the platform method to show NSOpenPanel, save the manifest file,
          // and copy the binary to the same directory
          debugPrint('Showing NSOpenPanel to save manifest and binary');
          // Wrap the binary data in Uint8List to ensure proper serialization
          final Uint8List binaryData = Uint8List.fromList(binaryBytes);
          debugPrint('Sending binary data to platform method: ${binaryData.length} bytes');
          
          final bool result = await _channel.invokeMethod('saveNativeMessagingHostManifest', {
            'content': manifestJson,
            'binary': binaryData,
            'binaryFilename': 'routine-nmh',
          });
          
          if (result) {
            debugPrint('Manifest and binary installation successful');
            // Try to connect to the Native Messaging Host after installation
            // This will trigger the extension connection flow
            Timer(const Duration(seconds: 2), () {
              connectToNMH();
            });
            return true;
          } else {
            debugPrint('Manifest and binary installation failed');
            // Log additional guidance for macOS security restrictions
            debugPrint('Note: If macOS security blocks the binary, the user may need to:');
            debugPrint('1. Open System Preferences > Security & Privacy');
            debugPrint('2. Look for a message about "routine-nmh" being blocked');
            debugPrint('3. Click "Allow Anyway" or "Open Anyway"');
            return false;
          }
        } catch (e) {
          debugPrint('Error saving manifest and binary: $e');
          return false;
        }
      } else if (Platform.isWindows) {
        // On Windows, the manifest goes in the registry
        // Use win32 package to write to the registry
        
        // Get the path to the native messaging host executable
        final Directory appDir = await getApplicationSupportDirectory();
        final String nmhPath = '${appDir.path}\\routine-nmh.exe';
        debugPrint('Native messaging host binary path: $nmhPath');
        
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
        debugPrint('Manifest content: $manifestJson');
        
        // Registry paths for Firefox
        const String mozillaRegistryPath = 
            'SOFTWARE\\Mozilla\\NativeMessagingHosts\\com.routine.nmh';
        debugPrint('Registry path: $mozillaRegistryPath');
            
        // Open the registry key (create if it doesn't exist)
        final Pointer<HKEY> hKey = calloc<HKEY>();
        
        try {
          // Create or open the key
          debugPrint('Creating registry key...');
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
            debugPrint('Failed to create registry key, error code: $result');
            return false;
          }
          
          // Write the manifest path to the registry
          // First, create a temporary file with the manifest
          final tempDir = await getTemporaryDirectory();
          final manifestFile = File('${tempDir.path}\\routine_manifest.json');
          debugPrint('Creating manifest file at: ${manifestFile.path}');
          
          await manifestFile.writeAsString(manifestJson);
          
          // Check if file was created successfully
          if (await manifestFile.exists()) {
            // Set the default value to the path of the manifest file
            final manifestPath = manifestFile.path;
            final Pointer<Utf16> manifestPathUtf16 = TEXT(manifestPath);
            debugPrint('Setting registry value to manifest path: $manifestPath');
            
            final int setValueResult = RegSetValueEx(
              hKey.value,
              nullptr,  // Default value
              0,
              REG_SZ,
              manifestPathUtf16.cast<Uint8>(),
              (manifestPath.length + 1) * 2,  // Include null terminator, *2 for UTF-16
            );
            
            if (setValueResult != ERROR_SUCCESS) {
              debugPrint('Failed to set registry value, error code: $setValueResult');
              return false;
            }
            
            // Close the registry key
            RegCloseKey(hKey.value);
            debugPrint('Windows manifest installation successful');
            return true;
          } else {
            debugPrint('Failed to create manifest file');
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
        debugPrint('Linux manifest directory: $manifestDir');
        
        // Get the path to the native messaging host executable
        final Directory appDir = await getApplicationSupportDirectory();
        final String nmhPath = '${appDir.path}/routine-nmh';
        debugPrint('Native messaging host binary path: $nmhPath');
        
        // Create directories if they don't exist
        final Directory dir = Directory(manifestDir);
        if (!await dir.exists()) {
          debugPrint('Creating manifest directory: $manifestDir');
          await dir.create(recursive: true);
        } else {
          debugPrint('Manifest directory already exists');
        }
        
        // Create the manifest file
        final File manifestFile = File('$manifestDir/com.routine.native_messaging.json');
        debugPrint('Creating manifest file at: ${manifestFile.path}');
        
        // Example manifest content
        final Map<String, dynamic> manifest = {
          'name': 'com.routine.nmh',
          'description': 'Routine Native Messaging Host',
          'path': nmhPath,
          'type': 'stdio',
          'allowed_extensions': ['routine@example.com']
        };
        
        final String manifestJson = json.encode(manifest);
        debugPrint('Manifest content: $manifestJson');
        
        await manifestFile.writeAsString(manifestJson);
        
        final bool exists = await manifestFile.exists();
        debugPrint('Linux manifest installation ${exists ? "successful" : "failed"}');
        return exists;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error installing native messaging host: $e');
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
