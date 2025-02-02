import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

  // breaks
  late final numBreaks = integer()();
  late final maxBreakDuration = integer()();
  late final frictionType = text()();
  late final frictionAmt = integer()();
  late final frictionSource = text()();

  late final breaks = text()();
}

@DataClassName('ConditionEntry')
class Conditions extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final routine = text().references(Routines, #id)();
  late final type = text()();
  late final value = text()();
  late final order = integer()();
  late final or = boolean()();
  late final lastCompletedAt = text().nullable()();
}

@DataClassName('DeviceEntry')
class Devices extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final name = text()();
  late final type = text()();
}

@DataClassName('GroupEntry')
class Groups extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final name = text().nullable()();
  late final device = text().references(Devices, #id)();
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

@DriftDatabase(tables: [Routines, Devices, Conditions, Groups, GroupItems, RoutineGroups])
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
}