import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/routine.dart';
import 'strict_mode_service.dart';
import 'package:cron/cron.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InstalledApplication {
  final String name;
  final String filePath;

  InstalledApplication({
    required this.name,
    required this.filePath,
  });

  @override
  String toString() => 'InstalledApplication(name: $name, filePath: $filePath)';
}

class DesktopService {
  // Singleton instance
  static final DesktopService _instance = DesktopService();

  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];

  DesktopService();

  static DesktopService get instance => _instance;

  final platform = const MethodChannel('com.routine.applist');
  Socket? _socket;
  bool _connected = false;
  List<int> _messageBuffer = [];
  int? _expectedLength;

  // Cache fields for blocked items
  List<String> _cachedSites = [];
  List<String> _cachedApps = [];
  List<String> _cachedCategories = [];
  bool _isAllowList = false;
  
  // Flag to track extension connection status
  bool _extensionConnected = false;

  // Set of browser names in lowercase for O(1) lookup
  final Set<String> _browserNames = {
    'firefox'
  };

  Future<void> init() async {
    await _connectToNMH();

    // Set up platform channel method handler
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'activeApplication':
          final appName = call.arguments as String;

          // Check if the active application is a browser using O(1) lookup
          final lowerAppName = appName.toLowerCase();
          if (_browserNames.any((browser) => lowerAppName.contains(browser))) {
            updateBlockedSites();
            
            // Check if we need to block browsers without extension
            _checkAndBlockBrowsersIfNeeded(appName);
          }
          break;
      }
    });

    // Signal to native code that Flutter is ready to receive messages
    try {
      await platform.invokeMethod('engineReady');
    } catch (e) {
      debugPrint('Failed to signal engine ready: $e');
    }

    Routine.watchAll().listen((routines) {
      onRoutinesUpdated(routines);
    });
  }

  void onRoutinesUpdated(List<Routine> routines) async {
    Set<Schedule> evaluationTimes = {};
    for (final Routine routine in routines) {
      evaluationTimes.add(Schedule(hours: routine.startHour, minutes: routine.startMinute));
      evaluationTimes.add(Schedule(hours: routine.endHour, minutes: routine.endMinute));

      if (routine.pausedUntil != null && routine.pausedUntil!.isAfter(DateTime.now())) {
        evaluationTimes.add(Schedule(hours: routine.pausedUntil!.hour, minutes: routine.pausedUntil!.minute));
      }
    }

    for (final ScheduledTask task in _scheduledTasks) {
      task.cancel();
    }
    _scheduledTasks.clear();

    for (final Schedule time in evaluationTimes) {
      ScheduledTask task = cron.schedule(time, () async {
        _evaluate(routines);
      });
      _scheduledTasks.add(task);
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isWindows || Platform.isLinux) {
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable
      );
    }
    
    _evaluate(routines);
  }

  void _evaluate(List<Routine> routines) {
    // Filter for active, not paused, and conditions not met routines
    routines = routines.where((r) => r.isActive && !r.isPaused && !r.areConditionsMet).toList();

    Set<String> apps = {}; 
    Set<String> sites = {};
    Set<String> categories = {};
    bool allowList = routines.any((r) => r.allow);
    
    if (allowList) {
      Map<String, int> appCounts = {};
      Map<String, int> siteCounts = {};
      Map<String, int> categoryCounts = {};

      for (final Routine routine in routines) {
        for (final String app in routine.apps) {
          appCounts[app] = (appCounts[app] ?? 0) + 1;
        }
        for (final String site in routine.sites) {
          siteCounts[site] = (siteCounts[site] ?? 0) + 1;
        }
        for (final String category in routine.categories) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      apps.addAll(appCounts.keys.where((app) => appCounts[app] == routines.length));
      sites.addAll(siteCounts.keys.where((site) => siteCounts[site] == routines.length));
      categories.addAll(categoryCounts.keys.where((category) => categoryCounts[category] == routines.length));
    } else {
      for (final Routine routine in routines) {
        apps.addAll(routine.apps);
        sites.addAll(routine.sites);
        categories.addAll(routine.categories);
      }
    }
    
    // Update cached values
    _cachedSites = sites.toList();
    _cachedApps = apps.toList();
    _cachedCategories = categories.toList();
    _isAllowList = allowList;

    // Update both apps and sites
    updateAppList();
    updateBlockedSites();
  }

  void dispose() {
    _socket?.close();
  }

  Future<void> _connectToNMH() async {
    try {
      _socket = await Socket.connect('127.0.0.1', 54322);
      debugPrint('Connected to NMH TCP server');
      _connected = true;

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
              // We have a complete message
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
          _connected = false;
          _setExtensionConnected(false);
          _blockBrowsersIfNeeded();
        },
        onDone: () {
          debugPrint('Socket closed');
          _connected = false;
          _setExtensionConnected(false);
          _blockBrowsersIfNeeded();
        },
      );
    } on SocketException catch (e) {
      _connected = false;
      if (e.osError?.errorCode == 61) {
        debugPrint('NMH service is not running. The app will continue without NMH features.');
      } else {
        debugPrint('Socket connection error: ${e.message}. The app will continue without NMH features.');
      }
    }
  }

  void _sendToNMH(String action, Map<String, dynamic> data) {
    if (!_connected) {
      debugPrint('Cannot send to NMH: not connected');
      _setExtensionConnected(false);
      return;
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
      _socket?.flush();
    } catch (e) {
      debugPrint('Failed to send message to NMH: $e');
    }
  }

  Future<void> updateAppList() async {
    // Update platform channel
    platform.invokeMethod('updateAppList', {
      'apps': _cachedApps,
      'categories': _cachedCategories,
      'allowList': _isAllowList,
    });
  }
  
  // Unblock all browsers when grace period starts
  void unblockAllBrowsers() {
    debugPrint('Grace period started, unblocking all browsers');
    
    // Create a copy of the current apps list
    final List<String> appsToBlock = List.from(_cachedApps);
    
    // Remove any browsers from the list
    bool removed = false;
    appsToBlock.removeWhere((app) {
      final lowerAppName = app.toLowerCase();
      final isBrowser = _browserNames.any((browser) => lowerAppName.contains(browser));
      if (isBrowser) {
        removed = true;
      }
      return isBrowser;
    });
    
    // Only update if we actually removed browsers
    if (removed) {
      debugPrint('Removed browsers from blocked apps list');
      // Update the platform with the modified list
      platform.invokeMethod('updateAppList', {
        'apps': appsToBlock,
        'categories': _cachedCategories,
        'allowList': _isAllowList,
      });
    }
  }
  
  // Check if we need to block browsers when extension isn't connected
  void _checkAndBlockBrowsersIfNeeded(String appName) async {
    final strictModeService = StrictModeService.instance;
    
    // If the setting to block browsers without extension is enabled
    if (strictModeService.effectiveBlockBrowsersWithoutExtension) {
      // If extension is not connected
      if (!_extensionConnected) {
        debugPrint('Browser detected without extension connected: $appName');
        
        // Check if we're in grace period - don't block during grace period
        if (strictModeService.isInExtensionGracePeriod) {
          debugPrint('In extension grace period, not blocking browser');
          
          // Create a temporary list of apps to block (excluding this browser)
          final List<String> appsToBlock = List.from(_cachedApps);
          final lowerAppName = appName.toLowerCase();
          
          // Remove this browser from the blocked apps list if it exists
          appsToBlock.removeWhere((app) => app.toLowerCase() == lowerAppName);
          
          // Update the platform with the list excluding this browser
          platform.invokeMethod('updateAppList', {
            'apps': appsToBlock,
            'categories': _cachedCategories,
            'allowList': _isAllowList,
          });
          
          return;
        }
        
        // Create a temporary list of apps to block
        final List<String> appsToBlock = List.from(_cachedApps);
        
        // Check if the browser is already in the list
        final lowerAppName = appName.toLowerCase();
        bool browserAlreadyBlocked = false;
        
        for (final app in appsToBlock) {
          if (app.toLowerCase() == lowerAppName) {
            browserAlreadyBlocked = true;
            break;
          }
        }
        
        // If browser is not already blocked, add it to the list
        if (!browserAlreadyBlocked) {
          debugPrint('Adding browser to blocked apps: $appName');
          appsToBlock.add(appName);
          
          // Update the platform with the temporary list including the browser
          platform.invokeMethod('updateAppList', {
            'apps': appsToBlock,
            'categories': _cachedCategories,
            'allowList': _isAllowList,
          });
        }
      } else {
        // Extension is connected
        // This is handled in _setExtensionConnected
      }
    }
  }

  Future<void> updateBlockedSites() async {
    if (!_connected) {
      debugPrint('Not connected to NMH, attempting connection...');
      await _connectToNMH();
      if (!_connected) {
        debugPrint('Failed to connect to NMH, skipping update');
        _setExtensionConnected(false);
        return;
      }
    }

    // Send update to NMH to forward to browser extension
    _sendToNMH('updateBlockedSites', {
      'sites': _cachedSites,
      'allowList': _isAllowList,
    });
    
    // Set extension connected to true when we successfully send an update
    _setExtensionConnected(true);
  }
  
  // Handle extension connection status changes
  void _setExtensionConnected(bool connected) {
    if (_extensionConnected != connected) {
      _extensionConnected = connected;
      debugPrint('Extension connection status changed: $_extensionConnected');
      
      if (_extensionConnected) {
        // Extension is now connected
        // End grace period if it was active
        StrictModeService.instance.endExtensionGracePeriod();
        
        // Unblock all browsers since extension is now connected
        if (StrictModeService.instance.blockBrowsersWithoutExtension) {
          unblockAllBrowsers();
        }
      } else {
        // Extension is now disconnected
        // Start blocking browsers if needed
        _blockBrowsersIfNeeded();
      }
    }
  }
  
  // Block all browsers when extension disconnects (if setting is enabled)
  void _blockBrowsersIfNeeded() {
    final strictModeService = StrictModeService.instance;
    
    // Only block browsers if the setting is enabled and not in grace period
    if (strictModeService.effectiveBlockBrowsersWithoutExtension && 
        !strictModeService.isInExtensionGracePeriod) {
      debugPrint('Extension disconnected, blocking all browsers');
      
      // Get list of browsers to block
      List<String> browsersToBlock = [];
      
      // Try to get a list of installed browsers
      try {
        // On macOS, we can look in the Applications folder
        if (Platform.isMacOS) {
          final Directory appDir = Directory('/Applications');
          if (appDir.existsSync()) {
            for (var entity in appDir.listSync(recursive: false)) {
              if (entity is Directory && entity.path.endsWith('.app')) {
                final String appName = entity.path.split('/').last.replaceAll('.app', '');
                final String lowerAppName = appName.toLowerCase();
                
                if (_browserNames.any((browser) => lowerAppName.contains(browser))) {
                  browsersToBlock.add(appName);
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error getting browser list: $e');
      }
      
      // If we couldn't get specific browsers, use generic browser names
      if (browsersToBlock.isEmpty) {
        browsersToBlock = _browserNames.toList();
      }
      
      // Create a copy of the current apps list
      final List<String> appsToBlock = List.from(_cachedApps);
      
      // Add all browsers to the block list if not already there
      bool changed = false;
      for (final String browser in browsersToBlock) {
        if (!appsToBlock.any((app) => app.toLowerCase() == browser.toLowerCase())) {
          appsToBlock.add(browser);
          changed = true;
        }
      }
      
      // Only update if we actually added browsers
      if (changed) {
        debugPrint('Added browsers to blocked apps list: $browsersToBlock');
        // Update the platform with the modified list
        platform.invokeMethod('updateAppList', {
          'apps': appsToBlock,
          'categories': _cachedCategories,
          'allowList': _isAllowList,
        });
      }
    }
  }

  Future<void> setStartOnLogin(bool enabled) async {
    // Check if strict mode is enabled and we're trying to disable startup
    final strictModeService = StrictModeService.instance;
    if (!enabled && strictModeService.blockDisablingSystemStartup) {
      debugPrint('Strict mode is enabled, cannot disable startup');
      return;
    }
    
    if (Platform.isWindows || Platform.isLinux) {
      try {
        // Ensure setup is done
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        launchAtStartup.setup(
          appName: packageInfo.appName,
          appPath: Platform.resolvedExecutable
        );
        
        final bool before = await launchAtStartup.isEnabled();
        debugPrint('Setting start on login to $before');
        if (enabled) {
          await launchAtStartup.enable();
        } else {
          await launchAtStartup.disable();
        }
        final bool result = await launchAtStartup.isEnabled();
        debugPrint('set start on login to $result');
      } catch (e) {
        debugPrint('Error setting start on login: $e');
      }
    } else {
      try {
        await platform.invokeMethod('setStartOnLogin', enabled);
      } catch (e) {
        debugPrint('Failed to set start on login: $e');
      }
    }
  }

  Future<bool> getStartOnLogin() async {
    if (Platform.isWindows || Platform.isLinux) {
      try {
        // Ensure setup is done
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        launchAtStartup.setup(
          appName: packageInfo.appName,
          appPath: Platform.resolvedExecutable
        );
        
        final bool enabled = await launchAtStartup.isEnabled();
        return enabled;
      } catch (e) {
        return false;
      }
    } else {
      try {
        final bool enabled = await platform.invokeMethod('getStartOnLogin');
        return enabled;
      } catch (e) {
        debugPrint('Failed to get start on login status: $e');
        return false;
      }
    }
  }

  static Future<List<InstalledApplication>> getInstalledApplications() async {
    List<InstalledApplication> installedApps = [];

    if (Platform.isWindows) {
      try {
        // Get installed applications from Windows registry
        // First, check the 64-bit applications
        final process64 = await Process.run('powershell.exe', [
          '-Command',
          'Get-ItemProperty HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\* | ' +
          'Where-Object { \$_.DisplayName -ne \$null } | ' +
          'Select-Object DisplayName, InstallLocation, UninstallString | ' +
          'ConvertTo-Json'
        ]);

        if (process64.exitCode == 0 && process64.stdout.toString().trim().isNotEmpty) {
          final List<dynamic> apps64 = json.decode(process64.stdout.toString());
          for (var app in apps64) {
            String name = app['DisplayName'] ?? '';
            String filePath = app['InstallLocation'] ?? '';
            
            // If InstallLocation is empty, try to extract from UninstallString
            if (filePath.isEmpty && app['UninstallString'] != null) {
              final uninstallString = app['UninstallString'].toString();
              final match = RegExp(r'"([^"]+)\\').firstMatch(uninstallString);
              if (match != null) {
                filePath = match.group(1) ?? '';
              }
            }
            
            if (name.isNotEmpty && !installedApps.any((a) => a.name == name)) {
              // Find the executable file in the installation directory
              String exePath = await _findExecutableForApp(name, filePath);
              installedApps.add(InstalledApplication(
                name: name,
                filePath: exePath.isNotEmpty ? exePath : filePath,
              ));
            }
          }
        }

        // Then check the 32-bit applications on 64-bit Windows
        final process32 = await Process.run('powershell.exe', [
          '-Command',
          'Get-ItemProperty HKLM:\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\* | ' +
          'Where-Object { \$_.DisplayName -ne \$null } | ' +
          'Select-Object DisplayName, InstallLocation, UninstallString | ' +
          'ConvertTo-Json'
        ]);

        if (process32.exitCode == 0 && process32.stdout.toString().trim().isNotEmpty) {
          final List<dynamic> apps32 = json.decode(process32.stdout.toString());
          for (var app in apps32) {
            String name = app['DisplayName'] ?? '';
            String filePath = app['InstallLocation'] ?? '';
            
            // If InstallLocation is empty, try to extract from UninstallString
            if (filePath.isEmpty && app['UninstallString'] != null) {
              final uninstallString = app['UninstallString'].toString();
              final match = RegExp(r'"([^"]+)\\').firstMatch(uninstallString);
              if (match != null) {
                filePath = match.group(1) ?? '';
              }
            }
            
            if (name.isNotEmpty && !installedApps.any((a) => a.name == name)) {
              // Find the executable file in the installation directory
              String exePath = await _findExecutableForApp(name, filePath);
              installedApps.add(InstalledApplication(
                name: name,
                filePath: exePath.isNotEmpty ? exePath : filePath,
              ));
            }
          }
        }
        
        // Also check user-specific installed applications
        final processUser = await Process.run('powershell.exe', [
          '-Command',
          'Get-ItemProperty HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\* | ' +
          'Where-Object { \$_.DisplayName -ne \$null } | ' +
          'Select-Object DisplayName, InstallLocation, UninstallString | ' +
          'ConvertTo-Json'
        ]);

        if (processUser.exitCode == 0 && processUser.stdout.toString().trim().isNotEmpty) {
          final dynamic userApps = json.decode(processUser.stdout.toString());
          // Handle both single object and array responses
          final List<dynamic> apps = userApps is List ? userApps : [userApps];
          
          for (var app in apps) {
            String name = app['DisplayName'] ?? '';
            String filePath = app['InstallLocation'] ?? '';
            
            // If InstallLocation is empty, try to extract from UninstallString
            if (filePath.isEmpty && app['UninstallString'] != null) {
              final uninstallString = app['UninstallString'].toString();
              final match = RegExp(r'"([^"]+)\\').firstMatch(uninstallString);
              if (match != null) {
                filePath = match.group(1) ?? '';
              }
            }
            
            if (name.isNotEmpty && !installedApps.any((a) => a.name == name)) {
              // Find the executable file in the installation directory
              String exePath = await _findExecutableForApp(name, filePath);
              installedApps.add(InstalledApplication(
                name: name,
                filePath: exePath.isNotEmpty ? exePath : filePath,
              ));
            }
          }
        }

        // Add common applications that might not be in the registry
        await _addCommonApplications(installedApps);
      } catch (e) {
        debugPrint('Error getting installed applications: $e');
      }
    } else if (Platform.isMacOS) {  
      Directory appDir = Directory('/Applications');
      if (await appDir.exists()) {
        await for (var entity in appDir.list(recursive: false)) {
          if (entity is Directory && entity.path.endsWith('.app')) {
            String appName = entity.path.split('/').last.replaceAll('.app', '');
            if (!installedApps.any((app) => app.name == appName)) {
              installedApps.add(InstalledApplication(
                name: appName,
                filePath: entity.path,
              ));
            }
          }
        }
      }
    }

    installedApps.sort((a, b) => a.name.compareTo(b.name));
    return installedApps;
  }

  // Helper method to find executable files for an application
  static Future<String> _findExecutableForApp(String appName, String installPath) async {
    if (installPath.isEmpty) return '';
    
    try {
      // First, try to find an executable with the same name as the app
      final sanitizedAppName = appName.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final possibleExeNames = [
        '$sanitizedAppName.exe',
        '${sanitizedAppName.replaceAll(' ', '')}.exe',
        sanitizedAppName.split(' ').first + '.exe',
      ];
      
      // Check if the directory exists
      final dir = Directory(installPath);
      if (!await dir.exists()) return installPath;
      
      // First, try to find the executable directly in the install path
      for (var exeName in possibleExeNames) {
        final exePath = '$installPath\\$exeName';
        final exeFile = File(exePath);
        if (await exeFile.exists()) {
          return exePath;
        }
      }
      
      // If not found, search recursively for any .exe files
      final exeFiles = <FileSystemEntity>[];
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
          exeFiles.add(entity);
        }
      }
      
      // If we found any .exe files, return the first one
      if (exeFiles.isNotEmpty) {
        return exeFiles.first.path;
      }
    } catch (e) {
      debugPrint('Error finding executable for $appName at $installPath: $e');
    }
    
    return installPath;
  }
  
  // Add common applications that might not be in the registry
  static Future<void> _addCommonApplications(List<InstalledApplication> installedApps) async {
    // List of common applications to check
    final List<Map<String, List<String>>> commonApps = [
      {
        'name': ['Discord'],
        'paths': [
          'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Local\\Discord\\',
        ]
      },
      {
        'name': ['Chrome'],
        'paths': [
          'C:\\Program Files\\Google\\Chrome\\Application\\',
          'C:\\Program Files (x86)\\Google\\Chrome\\Application\\',
        ]
      },
      {
        'name': ['Firefox'],
        'paths': [
          'C:\\Program Files\\Mozilla Firefox\\',
          'C:\\Program Files (x86)\\Mozilla Firefox\\',
        ]
      },
      {
        'name': ['Edge'],
        'paths': [
          'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\',
          'C:\\Program Files\\Microsoft\\Edge\\Application\\',
        ]
      },
    ];
    
    for (var app in commonApps) {
      final String appName = app['name']![0];
      
      // Skip if we already have this app
      if (installedApps.any((a) => a.name == appName)) continue;
      
      for (var basePath in app['paths']!) {
        try {
          final dir = Directory(basePath);
          if (await dir.exists()) {
            // For Discord, we need to find the app-X.X.XXXX folder
            if (appName == 'Discord') {
              await for (var entity in dir.list()) {
                if (entity is Directory && entity.path.contains('app-')) {
                  final exePath = '${entity.path}\\Discord.exe';
                  final exeFile = File(exePath);
                  if (await exeFile.exists()) {
                    installedApps.add(InstalledApplication(
                      name: appName,
                      filePath: exePath,
                    ));
                    break;
                  }
                }
              }
            } else {
              // For other apps, search for .exe files
              final exeFiles = <FileSystemEntity>[];
              await for (var entity in dir.list(recursive: false)) {
                if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
                  exeFiles.add(entity);
                }
              }
              
              if (exeFiles.isNotEmpty) {
                installedApps.add(InstalledApplication(
                  name: appName,
                  filePath: exeFiles.first.path,
                ));
              }
            }
          }
        } catch (e) {
          debugPrint('Error checking common app $appName: $e');
        }
      }
    }
  }
}
