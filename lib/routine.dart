import 'condition.dart';
import 'group.dart';
import 'manager.dart';
import 'package:flutter/material.dart';

enum FrictionType {
  none,
  delay,
  intention,
  code,
  nfc
}

class Routine {
  final String id;
  final String name;
  
  // scheduling
  final List<bool> _days;
  final int _startTime;
  final int _endTime;
  
  // breaks
  final int _numBreaks;
  final int _maxBreakDuration; // in minutes
  final FrictionType _frictionType;
  final int _frictionNum; // fixed delay, code length
  final String _frictionSource; // nfc id, code source

  // conditions
  final List<Condition> _conditions;

  // block
  final Map<String, String> _groupIds;

  Routine({
    required this.id, 
    required this.name,
    List<bool>? days,
    int startTime = -1,
    int endTime = -1,
    int numBreaks = -1,
    int maxBreakDuration = 15,
    FrictionType frictionType = FrictionType.none,
    int frictionNum = -1,
    String frictionSource = "",
    List<Condition>? conditions,
    Map<String, String> groupIds = const {}
  }) : _days = days ?? List.filled(7, true),
       _startTime = startTime,
       _endTime = endTime,
       _numBreaks = numBreaks,
       _maxBreakDuration = maxBreakDuration,
       _frictionType = frictionType,
       _frictionNum = frictionNum,
       _frictionSource = frictionSource,
       _conditions = conditions ?? [],
       _groupIds = groupIds {
    if (_days.length != 7) {
      throw Exception("Days must be a list of length 7");
    }
    if (_startTime >= 0 && _endTime >= 0) {
      final startHour = _startTime ~/ 60;
      final startMinute = _startTime % 60;
      final endHour = _endTime ~/ 60;
      final endMinute = _endTime % 60;
      
      if (startHour < 0 || startMinute < 0 || endHour < 0 || endMinute < 0) {
        throw Exception("Start time and end time must be non-negative");
      }

      if (startHour > 24 || startMinute > 60 || endHour > 24 || endMinute > 60) {
        throw Exception("Start time and end time must be in the range 0-1440");
      }
    }
  }

  List<bool> get days => List.unmodifiable(_days);
  int get startTime => _startTime;
  int get endTime => _endTime;
  int get numBreaks => _numBreaks;
  int get maxBreakDuration => _maxBreakDuration;
  FrictionType get frictionType => _frictionType;
  int get frictionNum => _frictionNum;
  String get frictionSource => _frictionSource;
  List<Condition> get conditions => List.unmodifiable(_conditions);
  Map<String, String> get groupIds => Map.unmodifiable(_groupIds);

  int get startHour => _startTime ~/ 60;
  int get startMinute => _startTime % 60;
  int get endHour => _endTime ~/ 60;
  int get endMinute => _endTime % 60;

  bool isActive() { 
    final DateTime now = DateTime.now();
    final int dayOfWeek = now.weekday - 1;

    if (!_days[dayOfWeek]) {
      return false;
    }
    
    final int currMins = now.hour * 60 + now.minute;
    
    // All day routine or not scheduled
    if (_startTime == -1 && _endTime == -1) {
      return _days[dayOfWeek] && !isComplete();
    }
    
    // Check if routine spans to next day (endTime < startTime)
    if (_endTime < _startTime) {
      // Active if current time is either after start time or before end time
      return (currMins >= _startTime || currMins < _endTime) && !isComplete();
    }
    
    // Normal case: routine starts and ends on same day
    return (currMins >= _startTime && currMins < _endTime) && !isComplete();
  }

  bool isComplete() { 
    if (_conditions.isEmpty) {
      return false;
    }

    for (final Condition condition in _conditions) {
      if (!condition.isComplete(_startTime, _endTime)) {
        return false;
      }
    }

    return true;
  }

  String? getGroupId() {
    final id = _groupIds[Manager().thisDevice.id];
    debugPrint('groupIds: ${_groupIds}, deviceId: ${Manager().thisDevice.id}, getGroupId: $id');
    return id;
  }

  Group? getGroup() {
    String? id = getGroupId();

    if (id == null || id.isEmpty) {
      return null;
    }

    return Manager().findBlockList(id);
  }
}