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
    _routineSubscription = Routine
      .watchAll()
      .listen((routines) => _sendRoutines(routines, false));
    
    _strictModeSubscription = StrictModeService.instance.settingsStream
      .listen(_sendStrictModeSettings);
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
  
  Future<void> _sendStrictModeSettings(Map<String, bool> settings) async {
    try {
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

    final dynamic appList = await _channel.invokeMethod('retrieveAllApps');

    logger.i("finished retrieving apps = ${appList.length}");

    for (final app in appList) {
      installedApps.add(InstalledApp(name: app['name']!, filePath: app['filePath']!));
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
  
  Future<bool> getBlockPermissions({bool request = false}) async {
    if (Platform.isIOS) {
      final bool isAuthorized = await _channel.invokeMethod('checkFamilyControlsAuthorization');

      if (isAuthorized) {
        return true;
      } else if (request) {
        return await _channel.invokeMethod('requestFamilyControlsAuthorization');
      } else {
        return false;
      }
    } else {
      bool hasOverlayPermission = await _channel.invokeMethod('checkOverlayPermission');
      bool hasAccessibilityPermission = await _channel.invokeMethod('checkAccessibilityPermission');
      
      if (request) {
        if (!hasOverlayPermission) {
          hasOverlayPermission = await _channel.invokeMethod('requestOverlayPermission');
        }
        
        if (!hasAccessibilityPermission) {
          hasAccessibilityPermission = await _channel.invokeMethod('requestAccessibilityPermission');
        }
      }
      
      return hasOverlayPermission && hasAccessibilityPermission;
    }
  }
}
