import 'package:uuid/uuid.dart';
import '../setup.dart';
import '../database/database.dart';
import 'group.dart';
import 'device.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../util.dart';
import 'condition.dart';
import 'syncable.dart';

class Routine implements Syncable {
  final String _id;
  String _name;
  
  @override
  String get id => _id;
  
  // scheduling
  final List<bool> _days;
  int _startTime;
  int _endTime;

  // break tracking
  int? _numBreaksTaken;
  DateTime? _lastBreakAt;
  DateTime? _pausedUntil;
  int? _maxBreaks;
  int _maxBreakDuration;
  FrictionType _friction;
  int? _frictionLen;
  DateTime? _snoozedUntil;
  bool strictMode = false;
  List<Condition> conditions = [];

  late final Map<String, Group> _groups;

  late RoutineEntry? _entry;


  static Stream<List<Routine>> watchAll() {
    return getIt<AppDatabase>()
      .watchRoutines()
      .map((entries) => entries.map((e) => Routine.fromEntry(e.routine, e.groups))
      .toList());
  }

  static Future<List<Routine>> getAll() async {
    final routines =  await getIt<AppDatabase>().getRoutines();
    return routines.map((e) => Routine.fromEntry(e.routine, e.groups)).toList();
  }

  Routine() :
    _id = Uuid().v4(),
    _name = 'Routine',
    _days = [true, true, true, true, true, true, true],
    _startTime = -1,
    _endTime = -1,
    _numBreaksTaken = null,
    _lastBreakAt = null,
    _pausedUntil = null,
    _maxBreaks = null,
    _maxBreakDuration = 15,
    _friction = FrictionType.delay,
    _frictionLen = null,
    _snoozedUntil = null,
    strictMode = false,
    conditions = [],
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
    _pausedUntil = entry.pausedUntil,
    _maxBreaks = entry.maxBreaks,
    _maxBreakDuration = entry.maxBreakDuration,
    _friction = entry.friction,
    conditions = List.from(entry.conditions),
    _frictionLen = entry.frictionLen,
    _snoozedUntil = entry.snoozedUntil,
    strictMode = entry.strictMode {
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
    _pausedUntil = other._pausedUntil,
    _maxBreaks = other._maxBreaks,
    _maxBreakDuration = other._maxBreakDuration,
    _friction = other._friction,
    _frictionLen = other._frictionLen,
    _snoozedUntil = other._snoozedUntil,
    conditions = other.conditions,
    strictMode = other.strictMode,
    _entry = other._entry {
      _groups = Map.fromEntries(
        other._groups.entries.map(
          (entry) => MapEntry(entry.key, Group.from(entry.value))
        )
      );
    }

  @override
  Future<void> save() async {
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
      pausedUntil: Value(_pausedUntil),
      maxBreaks: Value(_maxBreaks),
      maxBreakDuration: Value(_maxBreakDuration),
      friction: Value(_friction),
      frictionLen: Value(_frictionLen),
      snoozedUntil: Value(_snoozedUntil),
      updatedAt: Value(DateTime.now()),
      recurring: Value(true),
      conditions: Value(conditions),
      strictMode: Value(strictMode)
    ));
    scheduleSyncJob();
  }

  @override
  bool get saved => _entry != null;
  
  @override
  bool get modified => _entry == null || changes.isNotEmpty;
  
  @override
  void scheduleSyncJob() {
    SyncService().addJob(SyncJob(remote: false));
  }
  DateTime? get snoozedUntil => _snoozedUntil;

  @override
  Future<void> delete() async {
    await getIt<AppDatabase>().tempDeleteRoutine(_id);
    print('routine delete sync');
    scheduleSyncJob();
  }

  @override
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

    if (_entry!.strictMode != strictMode) {
      changes.add('strictMode');
    }

    if (_entry!.endTime != _endTime) {
      changes.add('endTime');
    }

    if (!setEquals(Set.from(_entry!.groups), _groups.values.map((g) => g.id).toSet()) || _groups.values.any((g) => g.modified)) {
      changes.add('groups');
    }

    if (!setEquals(Set.from(_entry!.conditions.map((c) => c.id)), conditions.map((g) => g.id).toSet()) || conditions.any((g) => g.modified)) {
      changes.add('conditions');
    }

    if (_entry!.numBreaksTaken != _numBreaksTaken) {
      changes.add('numBreaksTaken');
    }

    if (_entry!.lastBreakAt != _lastBreakAt) {
      changes.add('lastBreakAt');
    }

    if (_entry!.pausedUntil != _pausedUntil) {
      changes.add('pausedUntil');
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


  bool get valid {
    return _name.isNotEmpty && 
           _days.contains(true);
  }

  List<bool> get days => List.unmodifiable(_days);
  
  void updateDay(int index, bool value) {
    if (index >= 0 && index < 7) {
      _days[index] = value;
    }
  }
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
    if (_pausedUntil == null) return false;

    final now = DateTime.now().toUtc();
    return now.isBefore(_pausedUntil!);
  }

  bool get canBreak {
    // If maxBreaks is 0, breaks are disabled
    if (_maxBreaks == 0) {
      return false;
    }
    
    if (_maxBreaks == null || _numBreaksTaken == null || _numBreaksTaken! < _maxBreaks!) {
      return true;
    }

    if (_lastBreakAt == null && (_maxBreaks == null || _maxBreaks! > 0)) {
      return true;
    }

    print("canBreak: $_lastBreakAt = ${Util.isBeforeToday(_lastBreakAt!)}");

    final lastBreakTimeOfDay = _lastBreakAt!.hour * 60 + _lastBreakAt!.minute;

    if (Util.isBeforeToday(_lastBreakAt!) || lastBreakTimeOfDay < _startTime) {
      // Last break was before start time today, reset counter
      _numBreaksTaken = null;
      return true;
    }

    return false;
  }

  DateTime? get pausedUntil => _pausedUntil;

  Future<void> breakFor({int? minutes}) async {
    if (!canBreak) return;

    final duration = minutes ?? _maxBreakDuration;
    final now = DateTime.now();
    
    _lastBreakAt = now;
    _pausedUntil = now.add(Duration(minutes: duration));
    _numBreaksTaken = (_numBreaksTaken ?? 0) + 1;
    
    await save();
  }

  Future<void> endBreak() async {
    _pausedUntil = null;
    await save();
  }

  Map<String, Group> get groups => _groups;

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
  List<String> get categories => getGroup()?.categories ?? const [];
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
  
  int? get numBreaksTaken => _numBreaksTaken;

  int? get numBreaksLeft => _maxBreaks! - (_numBreaksTaken ?? 0);

  String get breaksLeftText {
    if (_maxBreaks == null) {
      return 'Unlimited';
    }

    if (numBreaksLeft == 0) {
      return 'No';
    }
    
    final taken = _numBreaksTaken ?? 0;
    final left = _maxBreaks! - taken;
    return left <= 0 ? 'No' : left.toString();
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

  DateTime get startedAt {
    final now = DateTime.now();
    
    return DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute, 
    );
  }

  bool isConditionMet(Condition condition) {
    final startedAt = this.startedAt;
    
    if (condition.lastCompletedAt != null && condition.lastCompletedAt!.isAfter(startedAt)) {
      return true;
    }
    
    return false;
  }

  bool get areConditionsMet {
    if (conditions.isEmpty) return false;

    return conditions.every((c) {
      return isConditionMet(c);
    });
  }

  void completeCondition(Condition condition, {bool complete = true}) {
    final index = conditions.indexWhere((c) => c.id == condition.id);
    if (index != -1) {
      conditions[index].lastCompletedAt = complete ? DateTime.now() : null;
      save();
    }
  }
}