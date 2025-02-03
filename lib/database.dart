import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'converters/string_list_converter.dart';
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

  late final changes = text().map(StringListTypeConverter())();
  late final deleted = boolean().nullable()();
  late final updatedAt = dateTime()();

  late final groups = text().map(StringListTypeConverter())();
}

@DataClassName('DeviceEntry')
class Devices extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final name = text()();
  late final type = text()();
  late final curr = boolean()();
}

@DataClassName('GroupEntry')
class Groups extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final name = text().nullable()();
  late final device = text().references(Devices, #id)();
  late final allow = boolean()();

  // device only
  late final apps = text().map(StringListTypeConverter())();
  late final sites = text().map(StringListTypeConverter())();

  late final changes = text().map(StringListTypeConverter())();
  late final deleted = boolean().nullable()();
  late final updatedAt = dateTime()();
}

@DriftDatabase(tables: [Routines, Devices, Groups])
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

  Stream<List<RoutineEntry>> watchRoutines() {
    return select(routines).watch();
  }

  Stream<List<GroupEntry>> getNamedGroups(String deviceId) {
    return (select(groups)..where((t) => t.device.equals(deviceId) & t.name.isNotNull())).watch();
  }

  Future<void> upsertRoutine(RoutinesCompanion routine) {
    return transaction(() async {
      final existingEntry = await (select(routines)..where((t) => t.id.equals(routine.id.value))).getSingleOrNull();
      if (existingEntry == null) {
        await into(routines).insert(routine);
      } else {
        final existingGroups = await (select(groups)..where((t) => t.id.isIn(existingEntry.groups))).get();

        final deleteIds = existingGroups
          .where((g) => g.name == null && !routine.groups.value.any((id) => id == g.id))
          .map((g) => g.id).toList();
        await (update(groups)..where((t) => t.id.isIn(deleteIds))).write(GroupsCompanion(deleted: Value(true)));

        await (update(routines)..where((t) => t.id.equals(routine.id.value))).write(routine);
      }
    });
  }

  Future<void> upsertGroup(GroupsCompanion group) async {
    await into(groups).insertOnConflictUpdate(group);
  }

  Future<void> tempDeleteRoutine(id) async {
    await (update(routines)..where((t) => t.id.equals(id))).write(RoutinesCompanion(deleted: Value(true)));
  }

  Future<void> deleteRoutine(id) async {
    await (delete(routines)..where((t) => t.id.equals(id))).go();
  }

  Future<void> tempDeleteGroup(id) async {
    await (update(groups)..where((t) => t.id.equals(id))).write(GroupsCompanion(deleted: Value(true)));
  }

  Future<void> deleteGroup(id) async {
    await (delete(groups)..where((t) => t.id.equals(id))).go();
  }

  Future<DeviceEntry?> getThisDevice() async {
    return await (select(devices)..where((t) => t.curr.equals(true))).getSingleOrNull();
  }

  Future<void> insertDevice(DeviceEntry entry) {
    return into(devices).insert(entry);
  }
}