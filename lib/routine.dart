import 'condition.dart';

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
  List<bool> _days = [true, true, true, true, true, true, true];
  int _startTime = -1;
  int _endTime = -1;
  
  // breaks
  int numBreaks = -1;
  int maxBreakDuration = 15; // in minutes
  FrictionType _frictionType = FrictionType.none;
  int _frictionNum = -1; // fixed delay, code length
  String _frictionSource = ""; // nfc id, code source

  // conditions
  List<Condition> conditions = [];

  // block
  String blockId = "";

  Routine({required this.id, required this.name});

  setDays(List<bool> days) {
    if (days.length != 7) {
      throw Exception("Days must be a list of length 7");
    }

    _days = days;
  }

  int get startTime => _startTime;
  int get endTime => _endTime;

  int get startHour => _startTime ~/ 60;
  int get startMinute => _startTime % 60;

  int get endHour => _endTime ~/ 60;
  int get endMinute => _endTime % 60;

  setTimeRange(int startHour, int startMinute, int endHour, int endMinute) {
    if (startHour < 0 || startMinute < 0 || endHour < 0 || endMinute < 0) {
      throw Exception("Start time and end time must be non-negative");
    }

    if (startHour > 24 || startMinute > 60 || endHour > 24 || endMinute > 60) {
      throw Exception("Start time and end time must be in the range 0-1440");
    }

    _startTime = startHour * 60 + startMinute;
    _endTime = endHour * 60 + endMinute; 
  }
  
  setAllDay() { 
    _startTime = -1;
    _endTime = -1; 
  }

  get frictionType => _frictionType;
  get frictionNum => _frictionNum;
  get frictionSource => _frictionSource;

  setFriction(FrictionType type, int num, String source) {
    // TODO: add validation based on type
    _frictionType = type;
    _frictionNum = num;
    _frictionSource = source;
  }

  isActive() { 
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

  isComplete() { 
    if (conditions.isEmpty) {
      return false;
    }

    for (final Condition condition in conditions) {
      if (!condition.isComplete(_startTime, _endTime)) {
        return false;
      }
    }

    return true;
  }
}