import 'package:Routine/services/platform_service.dart';
import 'package:Routine/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import '../models/routine.dart';
import 'strict_mode_service.dart';
import 'browser_extension_service.dart';
import 'sync_service.dart';
import 'package:cron/cron.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InstalledApplication {
  final String name;
  final String filePath;
  final String? displayName;

  InstalledApplication({
    required this.name,
    required this.filePath,
    this.displayName,
  });

  @override
  String toString() => 'InstalledApplication(name: $name, displayName: $displayName, filePath: $filePath)';
}

class DesktopService extends PlatformService {
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

  @override
  Future<void> init() async {
    try {
      await platform.invokeMethod('engineReady');
    } catch (e) {
      debugPrint('Failed to signal engine ready: $e');
    }

    Routine.watchAll().listen((routines) {
      if (SyncService().syncing) {
        return;
      }
      onRoutinesUpdated(routines);
    });

    BrowserExtensionService.instance.addConnectionListener((strictMode) {
      updateAppList();
      updateBlockedSites();
    });

    StrictModeService.instance.addEffectiveSettingsListener((settings) {
      if (settings.keys.contains('blockBrowsersWithoutExtension') || 
          settings.keys.contains('isInExtensionGracePeriod') || 
          settings.keys.contains('isInExtensionCooldown')) {
        updateAppList();
      }
    });
    
    StrictModeService.instance.addGracePeriodExpirationListener(() {
      updateAppList();
    });
    
    // Setup platform method channel handler for system wake events
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'systemWake':
          final timestamp = call.arguments is Map ? call.arguments['timestamp'] : 'unknown';
          debugPrint('=== SYSTEM WAKE EVENT ===');
          debugPrint('System wake event received at: $timestamp');
          debugPrint('Current time: ${DateTime.now().toIso8601String()}');
          
          // Log the current state before updating
          final routinesBefore = await Routine.getAll();
          debugPrint('Number of routines before update: ${routinesBefore.length}');
          final activeRoutines = routinesBefore.where((r) => r.isActive && !r.isPaused).length;
          debugPrint('Active routines before update: $activeRoutines');
          
          // Update routines
          debugPrint('refeshing service...');
          refresh();
          
          // Trigger a sync job to ensure database is up-to-date after wake
          debugPrint('Triggering database sync after system wake...');
          SyncService().addJob(SyncJob(remote: false, full: true));
          debugPrint('Sync job added to queue');
          
          // Log after update
          Future.delayed(const Duration(milliseconds: 500), () async {
            final routinesAfter = await Routine.getAll();
            debugPrint('Number of routines after update: ${routinesAfter.length}');
            final activeRoutinesAfter = routinesAfter.where((r) => r.isActive && !r.isPaused).length;
            debugPrint('Active routines after update: $activeRoutinesAfter');
            debugPrint('=== SYSTEM WAKE EVENT PROCESSING COMPLETE ===');
          });
          
          return null;
        default:
          debugPrint('Unknown method call: ${call.method}');
          throw PlatformException(
            code: 'Unimplemented',
            message: "Method ${call.method} not implemented",
          );
      }
    });
  }

  @override
  Future<void> refresh() async {
    SyncService().setupRealtimeSync();
    final routines = await Routine.getAll();
    onRoutinesUpdated(routines);
  }
  
  void onRoutinesUpdated(List<Routine> routines) async {
    final List<Schedule> evaluationTimes = Util.getEvaluationTimes(routines);

    for (final ScheduledTask task in _scheduledTasks) {
      task.cancel();
    }
    _scheduledTasks.clear();

    for (final Schedule time in evaluationTimes) {
      ScheduledTask task = cron.schedule(time, () async {
        evaluate(routines);
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
    
    evaluate(routines);
  }

  void evaluate(List<Routine> routines) {
    routines = routines.where((r) => r.isActive && !r.isPaused && !r.areConditionsMet).toList();

    Set<String> apps = {}; 
    Set<String> sites = {};
    Set<String> categories = {};
    bool allowList = routines.any((r) => r.allow);

    Set<String> excludeApps = {};
    Set<String> excludeSites = {};
    Set<String> excludeCategories = {};
    if (allowList) {
      for (final routine in routines.where((r) => !r.allow)) {
        excludeApps.addAll(routine.apps);
        excludeSites.addAll(routine.sites);
        excludeCategories.addAll(routine.categories);
      }

      routines = routines.where((r) => r.allow).toList();
    }

    for (final Routine routine in routines) {
      apps.addAll(routine.apps.where((a) => !excludeApps.contains(a)));
      sites.addAll(routine.sites.where((s) => !excludeSites.contains(s)));
      categories.addAll(routine.categories.where((c) => !excludeCategories.contains(c)));
    }
    
    // Update cached values
    _cachedSites = sites.toList();
    _cachedApps = apps.toList();
    _cachedCategories = categories.toList();
    _isAllowList = allowList;

    // Update both apps and sites
    updateAppList();
    updateBlockedSites();
    StrictModeService.instance.evaluateStrictMode(routines);
  }
  
  Future<void> updateAppList() async {
    final apps = List<String>.from(_cachedApps);

    if (StrictModeService.instance.effectiveBlockBrowsersWithoutExtension && 
        !BrowserExtensionService.instance.isExtensionConnected && 
        !StrictModeService.instance.isInExtensionGracePeriod) {
      final browsers = await BrowserExtensionService.instance.getInstalledSupportedBrowsers();
      apps.addAll(browsers);
    }
    platform.invokeMethod('updateAppList', {
      'apps': apps,
      'categories': _cachedCategories,
      'allowList': _isAllowList,
    });
  }
  
  // Update blocked sites in the browser extension
  Future<void> updateBlockedSites() async {
    await BrowserExtensionService.instance.sendToNMH('updateBlockedSites', {
      'sites': _cachedSites,
      'allowList': _isAllowList,
    });
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
        // Call the native method to get running applications
        final MethodChannel platform = const MethodChannel('com.routine.applist');
        final List<dynamic> runningApps = await platform.invokeMethod('getRunningApplications');
        
        // Convert the result to InstalledApplication objects
        for (final app in runningApps) {
          final String name = app['name'];
          final String path = app['path'];
          final String? displayName = app['displayName'];
          
          // Skip system processes and empty names
          if (name.isEmpty || 
              path.toLowerCase().contains('\\windows\\system32\\') ||
              path.toLowerCase().contains('\\windows\\syswow64\\')) {
            continue;
          }
          
          // Add to the list if not already present
          if (!installedApps.any((existingApp) => existingApp.filePath == path)) {
            installedApps.add(InstalledApplication(
              name: name,
              filePath: path,
              displayName: displayName,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error getting running applications: $e');
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

    installedApps.sort((a, b) => (a.displayName ?? a.name).compareTo(b.displayName ?? b.name));
    return installedApps;
  }
}
