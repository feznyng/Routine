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
  
  // Socket connection to Native Messaging Host
  Socket? _socket;
  List<int> _messageBuffer = [];
  int? _expectedLength;
  
  // Flag to track browser extension connection status
  // Since the extension starts the NMH, this also indicates if NMH is connected
  bool _extensionConnected = false;
  
  final Set<String> _browserNames = {
    'firefox'
  };
  
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
    } catch (e, st) {
      Util.report('Error opening browser to install browser extension for $browserName', e, st);
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
      logger.i('Connected to NMH TCP server');

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
                logger.i('Received from NMH: $decoded');
              } catch (e, st) {
                Util.report('Error decoding NMH message', e, st);
              }
            } else {
              break;
            }
          }
        },
        onError: (error) {
          Util.report('NMH socket error', error, null);
          setExtensionConnected(false);
        },
        onDone: () {
          logger.i('Socket closed');
          setExtensionConnected(false);
        },
      );
    } on SocketException catch (e) {
      setExtensionConnected(false);
      if (e.osError?.errorCode == 61) {
        logger.i('NMH service is not running. The app will continue without NMH features.');
      } else {
        logger.w('Socket connection error: ${e.message}. The app will continue without NMH features.');
      }
    }
  }
  
  // Send a message to the Native Messaging Host
  Future<void> sendToNMH(String action, Map<String, dynamic> data) async {
     if (!isExtensionConnected) {
      await connectToNMH();
      if (!isExtensionConnected) {
        logger.w('Failed to connect to NMH, skipping update');
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
    } catch (e, st) {
      Util.report('Failed to send message to NMH', e, st);
    }
  }

  void setExtensionConnected(bool connected) {
    if (_extensionConnected != connected) {
      _extensionConnected = connected;
      _connectionStreamController.add(_extensionConnected);
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
    _socket?.close();
    _connectionStreamController.close();
  }
}
