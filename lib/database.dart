import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'database.g.dart';

@DataClassName('RoutineEntry')
class Routines extends Table {
  late final id = text()();
  late final name = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // scheduling
  late final monday = boolean()();
  late final tuesday = boolean()();
  late final wednesday = boolean()();
  late final thursday = boolean()();
  late final friday = boolean()();
  late final saturday = boolean()();
  late final sunday = boolean()();
  late final startTime = integer()();
  late final endTime = integer()();

  late final changes = text()();
}

@DataClassName('DeviceEntry')
class Devices extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final name = text()();
  late final type = text()();
  late final thisDevice = boolean()();
}

@DataClassName('GroupEntry')
class Groups extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final name = text().nullable()();
  late final device = text().references(Devices, #id)();

  late final changes = text()();
}

@DataClassName('RoutineGroupEntry')
class RoutineGroups extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final routine = text().references(Routines, #id)();
  late final group = text().references(Groups, #id)();
}

// device only (no-sync)
@DataClassName('GroupItemEntry')
class GroupItems extends Table {
  late final value = text()();
  late final site = boolean()();
  late final group = text().references(Groups, #id)();

  @override
  Set<Column<Object>> get primaryKey => {group, value};
}

@DriftDatabase(tables: [Routines, Devices, Groups, GroupItems, RoutineGroups])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'routine_db',
      native: const DriftNativeOptions(),
    );
  }

  Future<void> initialize() async {
    if (!kDebugMode) {
      return;
    }
  }

  Stream<List<RoutineEntry>> getRoutines() {
    // merge in groups
    return select(routines).watch();
  }

  Future<RoutineGroupEntry> getGroupForCurrentDevice(String routineId) {
    return (select(routineGroups)..where((t) => t.routine.equals(routineId))).getSingle();
  }

  Future<int> upsertRoutine(RoutinesCompanion routine) {
    return into(routines).insertOnConflictUpdate(routine);
  }

  Future<DeviceEntry?> getThisDevice() async {
    return await (select(devices)..where((t) => t.thisDevice.equals(true))).getSingleOrNull();
  }

  Future<void> insertDevice(DeviceEntry entry) {
    return into(devices).insert(entry);
  }
}