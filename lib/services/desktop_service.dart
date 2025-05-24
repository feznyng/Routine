import 'package:Routine/models/installed_app.dart';
import 'package:Routine/services/auth_service.dart';
import 'package:Routine/services/platform_service.dart';
import 'package:Routine/util.dart';
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
import 'package:Routine/setup.dart';

class DesktopService extends PlatformService {
  // Singleton instance
  static final DesktopService _instance = DesktopService();

  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];

  DesktopService();

  static DesktopService get instance => _instance;

  final platform = const MethodChannel('com.solidsoft.routine');
  // Cache fields for blocked items
  List<String> _cachedSites = [];
  List<String> _cachedApps = [];
  List<String> _cachedCategories = [];
  bool _isAllowList = false;
  
  // Subscriptions
  StreamSubscription? _routineSubscription;
  StreamSubscription? _appSubscription;
  StreamSubscription? _strictModeSettingsSubscription;
  StreamSubscription? _gracePeriodExpirationSubscription;

  @override
  Future<void> init() async {
    _stopWatching();

    try {
      await platform.invokeMethod('engineReady');
    } catch (e, st) {
      Util.report('Failed to signal engine start', e, st);
    }

    _routineSubscription = Routine.watchAll().listen((routines) {
      onRoutinesUpdated(routines);
    });

    _appSubscription = BrowserExtensionService.instance.connectionStream.listen((strictMode) async {
      await updateAppList();
      await updateBlockedSites();
    });

    _strictModeSettingsSubscription = StrictModeService.instance.effectiveSettingsStream.listen((settings) {
      if (settings.keys.contains('blockBrowsersWithoutExtension') || 
          settings.keys.contains('isInExtensionGracePeriod') || 
          settings.keys.contains('isInExtensionCooldown')) {
        updateAppList();
      }
    });
    
    _gracePeriodExpirationSubscription = StrictModeService.instance.gracePeriodExpirationStream.listen((_) {
      updateAppList();
    });
    
    // Setup platform method channel handler for system wake events
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'systemWake':
          logger.i('=== SYSTEM WAKE EVENT ===');
          await AuthService().refreshSessionIfNeeded().then((_) async {
            _stopWatching();
            await SyncService().sync();
            await init();
          });
          
          logger.i('=== SYSTEM WAKE EVENT PROCESSING COMPLETE ===');

          return null;
        default:
          logger.e('Unknown method call: ${call.method}');
          throw PlatformException(
            code: 'Unimplemented',
            message: "Method ${call.method} not implemented",
          );
      }
    });
  }

  // Clean up resources
  void dispose() {
    _stopWatching();
    
    // Cancel all scheduled tasks
    for (final task in _scheduledTasks) {
      task.cancel();
    }
    _scheduledTasks.clear();
  }

  Future<void> _stopWatching() async {
    await _routineSubscription?.cancel();
    await _appSubscription?.cancel();
    await _strictModeSettingsSubscription?.cancel();
    await _gracePeriodExpirationSubscription?.cancel();
  }
  
  @override
  Future<void> refresh() async {
    SyncService().setupRealtimeSync();
    final routines = await Routine.getAll();
    onRoutinesUpdated(routines);
  }
  
  void onRoutinesUpdated(List<Routine> routines) async {
    Util.scheduleEvaluationTimes(routines, _scheduledTasks, () async {
      evaluate(routines);
    });

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
  }
  
  Future<void> updateAppList() async {
    final apps = List<String>.from(_cachedApps);

    if (StrictModeService.instance.effectiveBlockBrowsersWithoutExtension && 
        !BrowserExtensionService.instance.isExtensionConnected && 
        !StrictModeService.instance.isInExtensionGracePeriod) {
      final browsers = await BrowserExtensionService.instance.getInstalledSupportedBrowsers();
      apps.addAll(browsers);
    }
    await platform.invokeMethod('updateAppList', {
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
        
        if (enabled) {
          await launchAtStartup.enable();
        } else {
          await launchAtStartup.disable();
        }
        final bool result = await launchAtStartup.isEnabled();
        if (result == enabled) {
          Util.report('Failed to set launch at startup to correct value', Exception('start up setting change failure'), null);
        }
      } catch (e, st) {
        Util.report('error setting start on login to $enabled', e, st);
      }
    } else {
      try {
        await platform.invokeMethod('setStartOnLogin', enabled);
      } catch (e, st) {
        Util.report('error setting start on login to $enabled', e, st);
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
      } catch (e, st) {
        Util.report('failed retrieving startup on login status', e, st);
        return false;
      }
    } else {
      try {
        final bool enabled = await platform.invokeMethod('getStartOnLogin');
        return enabled;
      } catch (e, st) {
        Util.report('failed retrieving startup on login status', e, st);
        return false;
      }
    }
  }

  
  static Future<List<InstalledApp>> getInstalledApps() async {
    List<InstalledApp> installedApps = [];

    if (Platform.isWindows) {
      try {
        // Call the native method to get running applications
        final MethodChannel platform = const MethodChannel('com.solidsoft.routine');
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
            installedApps.add(InstalledApp(
              name: displayName ?? name,
              filePath: path
            ));
          }
        }
      } catch (e, st) {
        Util.report('error retrieving installed applications', e, st);
      }
    } else if (Platform.isMacOS) {  
      Directory appDir = Directory('/Applications');
      if (await appDir.exists()) {
        await for (var entity in appDir.list(recursive: false)) {
          if (entity is Directory && entity.path.endsWith('.app')) {
            String appName = entity.path.split('/').last.replaceAll('.app', '');
            if (!installedApps.any((app) => app.name == appName)) {
              installedApps.add(InstalledApp(
                name: appName,
                filePath: entity.path,
              ));
            }
          }
        }
      }
    }

    installedApps.sort((a, b) => (a.name).compareTo(b.name));
    return installedApps;
  }
}
