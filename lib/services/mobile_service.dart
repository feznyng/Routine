import 'dart:async';
import 'dart:io' show Platform;
import 'package:Routine/models/installed_app.dart';
import 'package:Routine/services/platform_service.dart';
import 'package:Routine/services/sync_service.dart';
import 'package:Routine/setup.dart';
import 'package:Routine/util.dart';
import 'package:flutter/services.dart';
import '../models/routine.dart';
import 'strict_mode_service.dart';

class MobileService extends PlatformService {
  static final MobileService _instance = MobileService._internal();
  
  factory MobileService() => _instance;
  
  MobileService._internal();
  
  final MethodChannel _channel = const MethodChannel('com.solidsoft.routine');
  
  StreamSubscription? _routineSubscription;
  StreamSubscription? _strictModeSubscription;
  
  @override
  Future<void> init() async {        
    checkAndRequestBlockingPermissions();
    
    _routineSubscription = Routine.watchAll().listen((routines) {
      _sendRoutines(routines, false);

      // we need to evaluate strict mode in case a strict routine is active after changes
      _sendStrictModeSettings();
    });
    
    _strictModeSubscription = StrictModeService.instance.effectiveSettingsStream.listen((_) {
      _sendStrictModeSettings();
    });
    
  }

  @override
  Future<void> refresh() async {
    SyncService().setupRealtimeSync();
    await stopWatching();
    await SyncService().sync();
    await init();
  }
  
  Future<void> stopWatching() async {
    await _routineSubscription?.cancel();
    _routineSubscription = null;
    await _strictModeSubscription?.cancel();
    _strictModeSubscription = null;
  }
  
  Future<void> _sendStrictModeSettings() async {
    try {
      final strictModeService = StrictModeService.instance;
      
      final Map<String, dynamic> settings = {
        'blockChangingTimeSettings': strictModeService.blockChangingTimeSettings,
        'blockUninstallingApps': strictModeService.blockUninstallingApps,
        'blockInstallingApps': strictModeService.blockInstallingApps,
        'inStrictMode': strictModeService.inStrictMode,
      };
      
      await _channel.invokeMethod('updateStrictModeSettings', settings);
    } catch (e, st) {
      Util.report('error sending strict mode settings', e, st);
    }
  }

  Future<void> updateRoutines({bool immediate = false}) async {
    final routines = await Routine.getAll();
    _sendRoutines(routines, immediate);
  }

  Future<List<InstalledApp>> getInstalledApps() async {
    List<InstalledApp> installedApps = [];

    logger.i("retrieving apps");

    final List<Map<String, dynamic>> appList = await _channel.invokeMethod('retrieveAllApps');

    logger.i("finished retrieving apps = ${appList.length}");

    for (final app in appList) {
      installedApps.add(InstalledApp(name: app['name'], filePath: app['filePath']));
    }

    return installedApps;
  }
  
  Future<void> _sendRoutines(List<Routine> routines, bool immediate) async {
    try {
      final List<Map<String, dynamic>> routineMaps = routines.where((routine) => routine.getGroup() != null).map((routine) {
        DateTime? conditionsLastMet;
        if (routine.conditions.isNotEmpty) {
          if (routine.conditions.any((condition) => condition.lastCompletedAt == null)) {
            conditionsLastMet = null;
          } else {
            conditionsLastMet = routine.conditions
                .map((condition) => condition.lastCompletedAt!)
                .reduce((earliest, date) => earliest.isBefore(date) ? earliest : date);
          }
        }
        
        return {
          'id': routine.id,
          'name': routine.name,
          'days': routine.days,
          'startTime': routine.startTime,
          'endTime': routine.endTime,
          'allDay': routine.allDay,
          'pausedUntil': routine.pausedUntil?.toUtc().toIso8601String(),
          'snoozedUntil': routine.snoozedUntil?.toUtc().toIso8601String(),
          'apps': routine.apps,
          'sites': routine.sites,
          'categories': routine.categories,
          'allow': routine.allow,
          'conditionsMet': routine.areConditionsMet,
          'conditionsLastMet': conditionsLastMet?.toUtc().toIso8601String(),
          'strictMode': routine.strictMode,
        };
      }).toList();
            
      await _channel.invokeMethod(immediate ? 'immediateUpdateRoutines' : 'updateRoutines', {'routines': routineMaps});
    } catch (e, st) {
      Util.report('error updating routines', e, st);
    }
  }
  
  static MobileService get instance => _instance;
  
  Future<bool> checkBlockPermissions() async {
    if (Platform.isIOS) {
      try {
        final bool isAuthorized = await _channel.invokeMethod('checkFamilyControlsAuthorization');
        return isAuthorized;
      } catch (e, st) {
        Util.report('error retrieving family controls authorization', e, st);
        return false;
      }
    } else {
      return await _channel.invokeMethod('checkOverlayPermission');
    }
  }
  
  Future<bool> requestBlockingPermissions() async {    
    if (Platform.isIOS) {
      try {
        final bool isAuthorized = await _channel.invokeMethod('requestFamilyControlsAuthorization');
        return isAuthorized;
      } catch (e, st) {
        Util.report('error requesting family controls auth', e, st);
        return false;
      }
    } else {
      return await _channel.invokeMethod('requestOverlayPermission');
    }
  }
  
  Future<bool> checkAndRequestBlockingPermissions() async {
    if (Platform.isIOS) {
      final bool isAuthorized = await checkBlockPermissions();
      if (isAuthorized) {
        return true;
      } else {
        return await requestBlockingPermissions();
      }
    } else {
      // For Android, we need both overlay permission and accessibility permission
      final bool hasOverlayPermission = await checkOverlayPermission();
      final bool hasAccessibilityPermission = await checkAccessibilityPermission();
      
      if (!hasOverlayPermission) {
        await requestOverlayPermission();
      }
      
      if (!hasAccessibilityPermission) {
        await requestAccessibilityPermission();
      }
      
      return hasOverlayPermission && hasAccessibilityPermission;
    }
  }
  
  // Website blocking methods
  
  /// Check if the accessibility service is enabled
  Future<bool> checkAccessibilityPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool hasPermission = await _channel.invokeMethod('checkAccessibilityPermission');
      return hasPermission;
    } catch (e, st) {
      Util.report('error checking accessibility permission', e, st);
      return false;
    }
  }
  
  /// Request the user to enable the accessibility service
  Future<bool> requestAccessibilityPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool result = await _channel.invokeMethod('requestAccessibilityPermission');
      return result;
    } catch (e, st) {
      Util.report('error requesting accessibility permission', e, st);
      return false;
    }
  }
  
  /// Check if the app has permission to draw overlays
  Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool hasPermission = await _channel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } catch (e, st) {
      Util.report('error checking overlay permission', e, st);
      return false;
    }
  }
  
  /// Request permission to draw overlays
  Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool result = await _channel.invokeMethod('requestOverlayPermission');
      return result;
    } catch (e, st) {
      Util.report('error requesting overlay permission', e, st);
      return false;
    }
  }
  
  /// Update the list of blocked websites
  Future<bool> updateBlockedWebsites(List<String> websites) async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool result = await _channel.invokeMethod('updateBlockedWebsites', {
        'websites': websites,
      });
      return result;
    } catch (e, st) {
      Util.report('error updating blocked websites', e, st);
      return false;
    }
  }
  
  /// Block YouTube website
  Future<bool> blockYouTubeWebsite() async {
    if (!Platform.isAndroid) return true;
    
    // First ensure we have the necessary permissions
    final bool hasPermissions = await checkAndRequestBlockingPermissions();
    if (!hasPermissions) {
      return false;
    }
    
    // Update the list of blocked websites to include YouTube domains
    return await updateBlockedWebsites([
      'youtube.com',
      'm.youtube.com',
      'youtu.be',
      'youtube-nocookie.com'
    ]);
  }
}
