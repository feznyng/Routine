import 'dart:async';
import 'dart:io' show Platform;
import 'package:Routine/services/platform_service.dart';
import 'package:Routine/services/sync_service.dart';
import 'package:Routine/util.dart';
import 'package:flutter/services.dart';
import '../models/routine.dart';
import 'strict_mode_service.dart';

class MobileService extends PlatformService {
  static final MobileService _instance = MobileService._internal();
  
  factory MobileService() => _instance;
  
  MobileService._internal();
  
  final MethodChannel _channel = const MethodChannel('com.routine.ios_channel');
  
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
    if (!Platform.isIOS) return false;
    
    try {
      final bool isAuthorized = await _channel.invokeMethod('checkFamilyControlsAuthorization');
      return isAuthorized;
    } catch (e, st) {
      Util.report('error retrieving family controls authorization', e, st);
      return false;
    }
  }
  
  Future<bool> requestBlockingPermissions() async {
    if (!Platform.isIOS) return false;
    
    try {
      final bool isAuthorized = await _channel.invokeMethod('requestFamilyControlsAuthorization');
      return isAuthorized;
    } catch (e, st) {
      Util.report('error requesting family controls auth', e, st);
      return false;
    }
  }
  
  Future<bool> checkAndRequestBlockingPermissions() async {
    if (!Platform.isIOS) return false;
    
    final bool isAuthorized = await checkBlockPermissions();
    if (isAuthorized) {
      return true;
    } else {
      return await requestBlockingPermissions();
    }
  }
}
