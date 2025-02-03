import 'package:uuid/uuid.dart';
import 'setup.dart';
import 'database.dart';
import 'group.dart';
import 'device.dart';

class Routine {
  final String _id;
  final String _name;
  
  // scheduling
  final List<bool> _days;
  int _startTime;
  int _endTime;

  late final Map<String, Group> _groups;

  late RoutineEntry? _entry;

  static Stream<List<Routine>> getAll() {
    return getIt<AppDatabase>()
      .getRoutines()
      .map((entries) => entries.map((e) => Routine.fromEntry(e)).toList());
  }

  Routine() :
    _id = Uuid().v4(),
    _name = 'Routine',
    _days = [true, true, true, true, true, true, true],
    _startTime = -1,
    _endTime = -1,
    _entry = null {
      _groups = {
        getIt<Device>().id: Group()
      };
    }

  Routine.fromEntry(RoutineEntry entry) : 
    _id = entry.id,
    _name = entry.name,
    _days = [entry.monday, entry.tuesday, entry.wednesday, entry.thursday, entry.friday, entry.saturday, entry.sunday],
    _startTime = entry.startTime,
    _endTime = entry.endTime {
      _groups = {};
      _entry = entry;
  }

  save() async {
    final changes = this.changes;
    await getIt<AppDatabase>().upsertRoutine(RoutineEntry(
      id: _id, 
      name: _name,
      monday: _days[0], 
      tuesday: _days[1], 
      wednesday: _days[2], 
      thursday: _days[3], 
      friday: _days[4], 
      saturday: _days[5], 
      sunday: _days[6], 
      startTime: _startTime, 
      endTime: _endTime,
      changes: changes,
      status: _entry == null ? Status.created : Status.updated
    ));

    final currGroup = getGroup();

    if (currGroup != null && currGroup.modified && currGroup.name == null) {
      currGroup.save();
    }
  }

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
  String get name => _name;
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
      _endTime = 1010;
    }
  }
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
      return _days[dayOfWeek];
    }
    
    if (_endTime < _startTime) {
      return (currMins >= _startTime || currMins < _endTime);
    }
    
    return (currMins >= _startTime && currMins < _endTime);
  }

  Group? getGroup() {
    final Device device = getIt<Device>();
    return _groups[device.id];
  }

  List<String> get apps => getGroup()?.apps ?? const [];
  List<String> get sites => getGroup()?.sites ?? const [];
  bool get allow => getGroup()?.allow ?? false;
}