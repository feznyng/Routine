import 'package:uuid/uuid.dart';
import 'setup.dart';
import 'database.dart';
import 'group.dart';
import 'device.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

class Routine {
  final String _id;
  String _name;
  
  // scheduling
  final List<bool> _days;
  int _startTime;
  int _endTime;

  // break tracking
  int? _numBreaksTaken;
  DateTime? _lastBreakAt;
  DateTime? _breakUntil;
  int? _maxBreaks;
  int _maxBreakDuration;
  FrictionType _friction;
  int? _frictionLen;
  DateTime? _snoozedUntil;

  late final Map<String, Group> _groups;

  late RoutineEntry? _entry;

  static Stream<List<Routine>> watchAll() {
    return getIt<AppDatabase>()
      .watchRoutines()
      .map((entries) => entries.map((e) => Routine.fromEntry(e.routine, e.groups))
      .toList());
  }

  Routine() :
    _id = Uuid().v4(),
    _name = 'Routine',
    _days = [true, true, true, true, true, true, true],
    _startTime = -1,
    _endTime = -1,
    _numBreaksTaken = null,
    _lastBreakAt = null,
    _breakUntil = null,
    _maxBreaks = null,
    _maxBreakDuration = 15,
    _friction = FrictionType.delay,
    _frictionLen = null,
    _snoozedUntil = null,
    _entry = null {
      _groups = {
        getIt<Device>().id: Group()
      };
    }

  Routine.fromEntry(RoutineEntry entry, List<GroupEntry> groups) : 
    _id = entry.id,
    _name = entry.name,
    _days = [entry.monday, entry.tuesday, entry.wednesday, entry.thursday, entry.friday, entry.saturday, entry.sunday],
    _startTime = entry.startTime,
    _endTime = entry.endTime,
    _numBreaksTaken = entry.numBreaksTaken,
    _lastBreakAt = entry.lastBreakAt,
    _breakUntil = entry.breakUntil,
    _maxBreaks = entry.maxBreaks,
    _maxBreakDuration = entry.maxBreakDuration,
    _friction = entry.friction,
    _frictionLen = entry.frictionLen,
    _snoozedUntil = entry.snoozedUntil {
      _entry = entry;

      _groups = {};
      for (final group in groups) {
        _groups[group.device] = Group.fromEntry(group);
      }
  }

  Routine.from(Routine other) :
    _id = other._id,
    _name = other._name,
    _days = List<bool>.from(other._days),
    _startTime = other._startTime,
    _endTime = other._endTime,
    _numBreaksTaken = other._numBreaksTaken,
    _lastBreakAt = other._lastBreakAt,
    _breakUntil = other._breakUntil,
    _maxBreaks = other._maxBreaks,
    _maxBreakDuration = other._maxBreakDuration,
    _friction = other._friction,
    _frictionLen = other._frictionLen,
    _snoozedUntil = other._snoozedUntil,
    _entry = other._entry {
      _groups = Map.fromEntries(
        other._groups.entries.map(
          (entry) => MapEntry(entry.key, Group.from(entry.value))
        )
      );
    }

  save() async {
    final changes = this.changes;

    for (final group in _groups.values) {
      group.save();
    }

    await getIt<AppDatabase>().upsertRoutine(RoutinesCompanion(
      id: Value(_id), 
      name: Value(_name),
      monday: Value(_days[0]), 
      tuesday: Value(_days[1]), 
      wednesday: Value(_days[2]), 
      thursday: Value(_days[3]), 
      friday: Value(_days[4]), 
      saturday: Value(_days[5]), 
      sunday: Value(_days[6]), 
      startTime: Value(_startTime), 
      endTime: Value(_endTime),
      groups: Value(_groups.values.map<String>((g) => g.id).toList()),
      changes: Value(changes),
      numBreaksTaken: Value(_numBreaksTaken),
      lastBreakAt: Value(_lastBreakAt),
      breakUntil: Value(_breakUntil),
      maxBreaks: Value(_maxBreaks),
      maxBreakDuration: Value(_maxBreakDuration),
      friction: Value(_friction),
      frictionLen: Value(_frictionLen),
      snoozedUntil: Value(_snoozedUntil),
      updatedAt: Value(DateTime.now()),
      createdAt: Value(_entry?.createdAt ?? DateTime.now()),
    ));
  }

  bool get saved => _entry != null;

  Future<void> delete() async {
    await getIt<AppDatabase>().tempDeleteRoutine(_id);
  }

  List<String> get changes {
    List<String> changes = [];

    if (_entry == null) {
      return changes;
    }

    if (_entry!.name != _name) {
      changes.add('name');
    }

    if (_entry!.monday != _days[0]) {
      changes.add('monday');
    }

    if (_entry!.tuesday != _days[1]) {
      changes.add('tuesday');
    }

    if (_entry!.wednesday != _days[2]) {
      changes.add('wednesday');
    }

    if (_entry!.thursday != _days[3]) {
      changes.add('thursday');
    }

    if (_entry!.friday != _days[4]) {
      changes.add('friday');
    }

    if (_entry!.saturday != _days[5]) {
      changes.add('saturday');
    }

    if (_entry!.sunday != _days[6]) {
      changes.add('sunday');
    }

    if (_entry!.startTime != _startTime) {
      changes.add('startTime');
    } 

    if (_entry!.endTime != _endTime) {
      changes.add('endTime');
    }

    if (!listEquals(_entry!.groups, _groups.values.map((g) => g.id).toList()) || _groups.values.any((g) => g.modified)) {
      changes.add('groups');
    }

    if (_entry!.numBreaksTaken != _numBreaksTaken) {
      changes.add('numBreaksTaken');
    }

    if (_entry!.lastBreakAt != _lastBreakAt) {
      changes.add('lastBreakAt');
    }

    if (_entry!.breakUntil != _breakUntil) {
      changes.add('breakUntil');
    }

    if (_entry!.maxBreaks != _maxBreaks) {
      changes.add('maxBreaks');
    }

    if (_entry!.maxBreakDuration != _maxBreakDuration) {
      changes.add('maxBreakDuration');
    }

    if (_entry!.friction != _friction) {
      changes.add('friction');
    }

    if (_entry!.frictionLen != _frictionLen) {
      changes.add('frictionLen');
    }

    if (_entry!.snoozedUntil != _snoozedUntil) {
      changes.add('snoozedUntil');
    }

    return changes;
  }

  bool get modified {
    if (_entry == null) return true;
    return changes.isNotEmpty;
  }

  bool get valid {
    return _name.isNotEmpty && 
           _days.contains(true);
  }

  String get id => _id;
  List<bool> get days => List.unmodifiable(_days);
  int get startTime => _startTime;
  int get endTime => _endTime;
  set startTime(int value) {
    if (value < 0 || value > 1440) { 
      throw Exception("Start time must be between 0 and 1440");
    }

    _startTime = value;
  }
  set endTime(int value) {
    if (value < 0 || value > 1440) { 
      throw Exception("End time must be between 0 and 1440");
    }

    _endTime = value;
  }
  bool get allDay => _startTime == -1 && _endTime == -1;
  set allDay(bool value) {
    if (value) {
      _startTime = -1;
      _endTime = -1;
    } else {
      _startTime = 540;
      _endTime = 1020;
    }
  }
  Map<String, String> get groupIds => {};

  int get startHour => _startTime ~/ 60;
  int get startMinute => _startTime % 60;
  int get endHour => _endTime ~/ 60;
  int get endMinute => _endTime % 60;

  String get name => _name;
  
  set name(String value) {
    _name = value.trim();
  }

  bool get isActive { 
    final DateTime now = DateTime.now();
    final int dayOfWeek = now.weekday - 1;

    if (!_days[dayOfWeek]) {
      return false;
    }
    
    final int currMins = now.hour * 60 + now.minute;
    
    if (_startTime == -1 && _endTime == -1) {
      return _days[dayOfWeek];
    }
    
    if (_endTime < _startTime) {
      return (currMins >= _startTime || currMins < _endTime);
    }
    
    return (currMins >= _startTime && currMins < _endTime);
  }

  bool get isPaused {
    if (_breakUntil == null) return false;
    return DateTime.now().isBefore(_breakUntil!);
  }

  bool get canPause {
    if (_maxBreaks == null || _numBreaksTaken == null || _numBreaksTaken! < _maxBreaks!) {
      return true;
    }

    if (_lastBreakAt != null) {
      final lastBreakTimeOfDay = _lastBreakAt!.hour * 60 + _lastBreakAt!.minute;
      if (lastBreakTimeOfDay < _startTime) {
        // Last break was before start time today, reset counter
        _numBreaksTaken = null;
        return true;
      }
    }

    return false;
  }

  Future<void> pause({int? minutes}) async {
    if (!canPause) return;

    final duration = minutes ?? _maxBreakDuration;
    final now = DateTime.now();
    
    _lastBreakAt = now;
    _breakUntil = now.add(Duration(minutes: duration));
    _numBreaksTaken = (_numBreaksTaken ?? 0) + 1;
    
    await save();
  }

  Group? getGroup([String? deviceId]) {
    deviceId = deviceId ?? getIt<Device>().id;
    return _groups[deviceId];
  }

  void setGroup(Group group, [String? deviceId]) {
    deviceId = deviceId ?? getIt<Device>().id;
    _groups[deviceId] = group;
  }

  List<String> get apps => getGroup()?.apps ?? const [];
  List<String> get sites => getGroup()?.sites ?? const [];
  bool get allow => getGroup()?.allow ?? false;

  // Break configuration getters
  int? get maxBreaks => _maxBreaks;
  set maxBreaks(int? value) {
    _maxBreaks = value;
  }

  int get maxBreakDuration => _maxBreakDuration;
  set maxBreakDuration(int value) {
    if (value < 1) throw Exception('Break duration must be at least 1 minute');
    _maxBreakDuration = value;
  }

  FrictionType get friction => _friction;
  set friction(FrictionType value) {
    _friction = value;
  }

  int? get frictionLen => _frictionLen;
  set frictionLen(int? value) {
    _frictionLen = value;
  }

  int calculateDelay() {
    if (_frictionLen != null) return _frictionLen!;
    return (_numBreaksTaken ?? 0) * 30; // 30 seconds per break taken
  }

  int calculateCodeLength() {
    if (_frictionLen != null) return _frictionLen!;
    return (_numBreaksTaken ?? 0) * 2 + 4; // Base 4 chars + 2 per break taken
  }
}