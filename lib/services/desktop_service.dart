import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import '../models/routine.dart';
import 'strict_mode_service.dart';
import 'browser_extension_service.dart';
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
  // Cache fields for blocked items
  List<String> _cachedSites = [];
  List<String> _cachedApps = [];
  List<String> _cachedCategories = [];
  bool _isAllowList = false;

  Future<void> init() async {
    // Initialize browser extension service
    final browserExtensionService = BrowserExtensionService.instance;
    await browserExtensionService.init();
    
    // Set up listener for extension connection status changes
    browserExtensionService.addConnectionListener(_handleExtensionConnectionChange);
    
    // Also listen to the stream for future integrations
    browserExtensionService.connectionStream.listen(_handleExtensionConnectionChange);

    // Set up platform channel method handler
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'activeApplication':
          final appName = call.arguments as String;

          // Check if the active application is a browser
          if (browserExtensionService.isBrowser(appName)) {
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
    // Clean up resources
    final browserExtensionService = BrowserExtensionService.instance;
    browserExtensionService.removeConnectionListener(_handleExtensionConnectionChange);
    browserExtensionService.dispose();
  }
  
  // Handle extension connection status changes
  void _handleExtensionConnectionChange(bool connected) {
    if (connected) {
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
      // Use unawaited to avoid blocking the callback
      _blockBrowsersIfNeeded(); // This is now async but we don't need to await it
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
    
    final browserExtensionService = BrowserExtensionService.instance;
    
    // Create a copy of the current apps list
    final List<String> appsToBlock = List.from(_cachedApps);
    
    // Remove any browsers from the list
    bool removed = false;
    appsToBlock.removeWhere((app) {
      final isBrowser = browserExtensionService.isBrowser(app);
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
    final browserExtensionService = BrowserExtensionService.instance;
    
    // If the setting to block browsers without extension is enabled
    if (strictModeService.effectiveBlockBrowsersWithoutExtension) {
      // If extension is not connected
      if (!browserExtensionService.isExtensionConnected) {
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
      }
    }
  }
  
  // Update blocked sites in the browser extension
  Future<void> updateBlockedSites() async {
    await BrowserExtensionService.instance.sendToNMH('updateBlockedSites', {
      'sites': _cachedSites,
      'allowList': _isAllowList,
    });
  }
  
  // Block all browsers when extension disconnects (if setting is enabled)
  Future<void> _blockBrowsersIfNeeded() async {
    final strictModeService = StrictModeService.instance;
    final browserExtensionService = BrowserExtensionService.instance;
    
    // Only block browsers if the setting is enabled and not in grace period
    if (strictModeService.inStrictMode && 
        strictModeService.effectiveBlockBrowsersWithoutExtension && 
        !strictModeService.isInExtensionGracePeriod) {
      debugPrint('Extension disconnected, blocking all browsers');
      
      // Use BrowserExtensionService to get installed browsers
      List<String> browsersToBlock = await browserExtensionService.getInstalledSupportedBrowsers();
      final List<String> appsToBlock = List.from(_cachedApps);
      
      bool changed = false;
      for (final String browser in browsersToBlock) {
        if (!appsToBlock.any((app) => app.toLowerCase() == browser.toLowerCase())) {
          appsToBlock.add(browser);
          changed = true;
        }
      }
      
      if (changed) {
        debugPrint('Added browsers to blocked apps list: $browsersToBlock');
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
}
