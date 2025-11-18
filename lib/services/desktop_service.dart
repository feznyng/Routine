import 'dart:io';
import 'dart:async';

import 'package:Routine/setup.dart';
import 'package:cron/cron.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:Routine/channels/desktop_channel.dart';
import 'package:Routine/models/installed_app.dart';
import '../models/routine.dart';
import 'package:Routine/services/auth_service.dart';
import 'package:Routine/services/platform_service.dart';
import 'package:Routine/util.dart';
import 'strict_mode_service.dart';
import 'browser_service.dart';
import 'sync_service.dart';

class DesktopService extends PlatformService {
  static final DesktopService _instance = DesktopService();

  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];

  DesktopService();

  static DesktopService get instance => _instance;

  final _desktopChannel = DesktopChannel.instance;
  List<String> _cachedSites = [];
  List<String> _cachedApps = [];
  List<String> _cachedCategories = [];
  bool _isAllowList = false;
  StreamSubscription? _routineSubscription;
  StreamSubscription? _appSubscription;
  StreamSubscription? _strictModeSettingsSubscription;
  StreamSubscription? _gracePeriodExpirationSubscription;

  @override
  Future<void> init() async {
    _stopWatching();

    await _desktopChannel.signalEngineReady();

    await BrowserService.instance.init();

    _routineSubscription = Routine.watchAll().listen((routines) {
      onRoutinesUpdated(routines);
    });

    _appSubscription = BrowserService.instance.connectionStream.listen((_) async {
      await updateAppList();
      await updateBlockedSites();
    });
    
    _gracePeriodExpirationSubscription = BrowserService.instance.gracePeriodStream.listen((_) {
      updateAppList();
    });

    _strictModeSettingsSubscription = StrictModeService.instance.effectiveSettingsStream.listen((settings) {
      if (settings.keys.contains('blockBrowsersWithoutExtension') || 
          settings.keys.contains('isInExtensionGracePeriod') || 
          settings.keys.contains('isInExtensionCooldown')) {
        updateAppList();
      }
    });
    _desktopChannel.registerSystemWakeHandler(() async {
      await AuthService().refreshSessionIfNeeded().then((_) async {
        await _stopWatching();
        SyncService().setupRealtimeSync();
        await SyncService().sync();
        
        await init();
      });
    });
  }
  void dispose() {
    _stopWatching();
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
  Future<void> resume() async {
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
    _cachedSites = sites.toList();
    _cachedApps = apps.toList();
    _cachedCategories = categories.toList();
    _isAllowList = allowList;
    updateAppList();
    updateBlockedSites();
  }
  
  Future<void> updateAppList() async {
    final apps = List<String>.from(_cachedApps);

    if (StrictModeService.instance.effectiveBlockBrowsersWithoutExtension && !BrowserService.instance.isInGracePeriod) {
      final browsers = await BrowserService.instance.getInstalledSupportedBrowsers(connected: false, controlled: false);
      apps.addAll(browsers.map((b) => b.app.filePath));
      logger.i("added disconnected browsers: $browsers");
    }

    await _desktopChannel.updateBlockingList(
      apps: apps,
      sites: _cachedSites,
      categories: _cachedCategories,
      allowList: _isAllowList,
    );
  }
  Future<void> updateBlockedSites() async {
    logger.i("updateBlockedSites");
    await BrowserService.instance.sendToBrowser('updateBlockedSites', {
      'sites': _cachedSites,
      'allowList': _isAllowList,
    });
  }

  Future<void> setStartOnLogin(bool enabled) async {
    final strictModeService = StrictModeService.instance;
    if (!enabled && strictModeService.blockDisablingSystemStartup) {
      return;
    }
    
    if (Platform.isWindows || Platform.isLinux) {
      try {
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
      await _desktopChannel.setStartOnLogin(enabled);
    }
  }

  Future<bool> getStartOnLogin() async {
    if (Platform.isWindows || Platform.isLinux) {
      try {
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
      return await _desktopChannel.getStartOnLogin();
    }
  }

  
  Future<List<InstalledApp>> getInstalledApps() async {
    List<InstalledApp> installedApps = [];

    if (Platform.isWindows) {
      installedApps = await _desktopChannel.getRunningApplications();
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
