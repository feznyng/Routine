import 'condition.dart';
import 'setup.dart';
import 'database.dart';

enum FrictionType {
  none,
  delay,
  intention,
  code,
  nfc
}

class Routine {
  final String _id;
  final String _name;
  
  // scheduling
  final List<bool> _days;
  final int _startTime;
  final int _endTime;
  
  // breaks
  final int _numBreaks;
  final int _maxBreakDuration; // in minutes
  final FrictionType _frictionType;
  final int _frictionAmt; // fixed delay, code length
  final String _frictionSource; // nfc id, code source

  static Stream<List<Routine>> getAll() => getIt<AppDatabase>().getRoutines().map((entries) => entries.map((e) => Routine.fromEntry(e)).toList());

  Routine() :
    _id = '',
    _name = '',
    _days = [true, true, true, true, true, true, true],
    _startTime = -1,
    _endTime = -1,
    _numBreaks = 0,
    _maxBreakDuration = 0,
    _frictionType = FrictionType.none,
    _frictionAmt = 0,
    _frictionSource = '';

  Routine.fromEntry(RoutineEntry entry) : 
      _id = entry.id,
      _name = entry.name,
      _days = [entry.monday, entry.tuesday, entry.wednesday, entry.thursday, entry.friday, entry.saturday, entry.sunday],
      _startTime = entry.startTime,
      _endTime = entry.endTime,
      _numBreaks = entry.numBreaks,
      _maxBreakDuration = entry.maxBreakDuration,
      _frictionType = FrictionType.values.byName(entry.frictionType),
      _frictionAmt = entry.frictionAmt,
      _frictionSource = entry.frictionSource
      {
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

  String get id => _id;
  String get name => _name;
  List<bool> get days => List.unmodifiable(_days);
  int get startTime => _startTime;
  int get endTime => _endTime;
  int get numBreaks => _numBreaks;
  int get maxBreakDuration => _maxBreakDuration;
  FrictionType get frictionType => _frictionType;
  int get frictionAmt => _frictionAmt;
  String get frictionSource => _frictionSource;
  List<Condition> get conditions => [];
  Map<String, String> get groupIds => {};

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
    
    if (_startTime == -1 && _endTime == -1) {
      return _days[dayOfWeek] && !isComplete();
    }
    
    if (_endTime < _startTime) {
      return (currMins >= _startTime || currMins < _endTime) && !isComplete();
    }
    
    return (currMins >= _startTime && currMins < _endTime) && !isComplete();
  }

  bool isComplete() { 
    // TODO: implement
    return false;
  }

  List<String> get apps => [];
  List<String> get sites => [];
  bool get allow => false;
}