import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../models/routine.dart';
import 'strict_mode_service.dart';

class IOSService {
  static final IOSService _instance = IOSService._internal();
  
  factory IOSService() => _instance;
  
  IOSService._internal();
  
  final MethodChannel _channel = const MethodChannel('com.routine.ios_channel');
  
  StreamSubscription? _routineSubscription;
  
  void init() {
    _routineSubscription?.cancel();
    
    _routineSubscription = Routine.watchAll().listen((routines) {
      _sendRoutinesToIOS(routines);
      _sendStrictModeSettingsToIOS();
    });
    
    // Check for FamilyControls authorization on initialization
    checkAndRequestFamilyControlsAuthorization();
    _sendStrictModeSettingsToIOS();
  }
  
  void stopWatchingRoutines() {
    _routineSubscription?.cancel();
    _routineSubscription = null;
  }
  
  Future<void> _sendStrictModeSettingsToIOS() async {
    try {
      final strictModeService = StrictModeService.instance;
      
      // Use the underlying settings, not the effective ones
      final Map<String, dynamic> settings = {
        'blockChangingTimeSettings': strictModeService.blockChangingTimeSettings,
        'blockUninstallingApps': strictModeService.blockUninstallingApps,
        'blockInstallingApps': strictModeService.blockInstallingApps,
        'inStrictMode': strictModeService.inStrictMode,
      };
      
      // Send settings to iOS via platform channel
      await _channel.invokeMethod('updateStrictModeSettings', settings);
    } catch (e) {
      print('Error sending strict mode settings to iOS: $e');
    }
  }
  
  Future<void> _sendRoutinesToIOS(List<Routine> routines) async {
    try {
      final List<Map<String, dynamic>> routineMaps = routines.where((routine) => routine.getGroup() != null).map((routine) {
        // Calculate conditionsLastMet based on the specified logic
        DateTime? conditionsLastMet;
        if (routine.conditions.isNotEmpty) {
          // Check if any condition has lastCompletedAt set to null
          if (routine.conditions.any((condition) => condition.lastCompletedAt == null)) {
            conditionsLastMet = null;
          } else {
            // Find the earliest lastCompletedAt date among all conditions
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
            
      await _channel.invokeMethod('updateRoutines', {'routines': routineMaps});
    } catch (e) {
      print('Error sending routines to iOS: $e');
    }
  }
  
  static IOSService get instance => _instance;
  
  /// Checks if the app has FamilyControls authorization
  Future<bool> checkFamilyControlsAuthorization() async {
    if (!Platform.isIOS) return false;
    
    try {
      final bool isAuthorized = await _channel.invokeMethod('checkFamilyControlsAuthorization');
      return isAuthorized;
    } catch (e) {
      print('Error checking FamilyControls authorization: $e');
      return false;
    }
  }
  
  /// Requests FamilyControls authorization from the user
  Future<bool> requestFamilyControlsAuthorization() async {
    if (!Platform.isIOS) return false;
    
    try {
      final bool isAuthorized = await _channel.invokeMethod('requestFamilyControlsAuthorization');
      return isAuthorized;
    } catch (e) {
      print('Error requesting FamilyControls authorization: $e');
      return false;
    }
  }
  
  /// Checks current authorization status and requests if not authorized
  Future<bool> checkAndRequestFamilyControlsAuthorization() async {
    if (!Platform.isIOS) return false;
    
    final bool isAuthorized = await checkFamilyControlsAuthorization();
    if (isAuthorized) {
      return true;
    } else {
      return await requestFamilyControlsAuthorization();
    }
  }
}
