import 'dart:async';
import 'package:flutter/services.dart';
import 'routine.dart';

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
    });
  }
  
  void stopWatchingRoutines() {
    _routineSubscription?.cancel();
    _routineSubscription = null;
  }
  
  Future<void> _sendRoutinesToIOS(List<Routine> routines) async {
    try {
      final List<Map<String, dynamic>> routineMaps = routines.where((routine) => routine.getGroup() != null).map((routine) {
        return {
          'id': routine.id,
          'name': routine.name,
          'days': routine.days,
          'startTime': routine.startTime,
          'endTime': routine.endTime,
          'allDay': routine.allDay,
          'pausedUntil': routine.pausedUntil?.toIso8601String(),
          'snoozedUntil': routine.snoozedUntil?.toIso8601String(),
          'apps': routine.apps,
          'sites': routine.sites,
          'categories': routine.categories,
          'allow': routine.allow
        };
      }).toList();
            
      await _channel.invokeMethod('updateRoutines', {'routines': routineMaps});
    } catch (e) {
      print('Error sending routines to iOS: $e');
    }
  }
  
  static IOSService get instance => _instance;
}
