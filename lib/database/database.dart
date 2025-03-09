import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'string_list_converter.dart';
import '../models/condition.dart';
part 'database.g.dart';

enum FrictionType {
  none,
  delay,
  intention,
  code
}

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
  late final recurring = boolean()();

  late final changes = text().map(StringListTypeConverter())();
  late final deleted = boolean().clientDefault(() => false)();
  late final updatedAt = dateTime()();

  late final groups = text().map(StringListTypeConverter())();

  // breaks
  late final numBreaksTaken = integer().nullable()();
  late final lastBreakAt = dateTime().nullable()();
  late final pausedUntil = dateTime().nullable()();
  late final maxBreaks = integer().nullable()();
  late final maxBreakDuration = integer().clientDefault(() => 15)();
  late final friction = textEnum<FrictionType>()();
  late final frictionLen = integer().nullable()();
  late final snoozedUntil = dateTime().nullable()();

  late final conditions = text().map(const ConditionConverter())();
  late final strictMode = boolean().clientDefault(() => false)();
}

@DataClassName('DeviceEntry')
class Devices extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  late final name = text()();
  late final type = text()();
  late final curr = boolean()();
  late final deleted = boolean().clientDefault(() => false)();

  late final changes = text().map(StringListTypeConverter())();
  late final updatedAt = dateTime()();

  late final lastPulledAt = dateTime().nullable()();
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
  late final apps = text().clientDefault(() => '[]').map(StringListTypeConverter())();
  late final sites = text().clientDefault(() => '[]').map(StringListTypeConverter())();
  late final categories = text().clientDefault(() => '[]').map(StringListTypeConverter())();

  late final changes = text().map(StringListTypeConverter())();
  late final deleted = boolean().clientDefault(() => false)();
  late final updatedAt = dateTime()();
}

typedef RoutineWithGroups = ({
  RoutineEntry routine,
  List<GroupEntry> groups,
});

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

  Future<List<RoutineEntry>> getRoutinesById(List<String> ids) {
    return (select(routines)..where((t) => t.id.isIn(ids))).get();
  }

  Future<DateTime?> getLastPulledAt() async {
    final entry = await (select(devices)..where((t) => t.curr.equals(true))).getSingleOrNull();
    return entry?.lastPulledAt;
  }

  Stream<List<DeviceEntry>> watchDevices() {
    return (select(devices)..where((t) => t.deleted.equals(false))).watch();
  }

  Stream<List<RoutineWithGroups>> watchRoutines() {
    final referencedItems = routines.groups.jsonEach(this);

    final routineWithGroups = select(routines).join(
      [
        innerJoin(referencedItems, const Constant(true), useColumns: false),
        innerJoin(
          groups,
          groups.id.equalsExp(referencedItems.value.cast()) & groups.deleted.equals(false),
        ),
      ],
    )..where(routines.deleted.equals(false));

    return routineWithGroups.watch().map((rows) {
      final groupsByRoutine = <String, List<GroupEntry>>{};
      final routinesById = <String, RoutineEntry>{};

      for (final row in rows) {
        final routine = row.readTable(routines);
        final group = row.readTable(groups);

        groupsByRoutine.putIfAbsent(routine.id, () => []).add(group);
        routinesById[routine.id] = routine;
      }

      return [
        for (final entry in groupsByRoutine.entries)
          (routine: routinesById[entry.key]!, groups: entry.value)
      ];
    });
  }

  Future<List<RoutineWithGroups>> getRoutines() async {
    final referencedItems = routines.groups.jsonEach(this);

    final routineWithGroups = select(routines).join(
      [
        innerJoin(referencedItems, const Constant(true), useColumns: false),
        innerJoin(
          groups,
          groups.id.equalsExp(referencedItems.value.cast()) & groups.deleted.equals(false),
        ),
      ],
    )..where(routines.deleted.equals(false));

    final routinesWithGroups = await routineWithGroups.get();
    final groupsByRoutine = <String, List<GroupEntry>>{};
    final routinesById = <String, RoutineEntry>{};

    for (final row in routinesWithGroups) {
      final routine = row.readTable(routines);
      final group = row.readTable(groups);

      groupsByRoutine.putIfAbsent(routine.id, () => []).add(group);
      routinesById[routine.id] = routine;
    }

    return [
      for (final entry in groupsByRoutine.entries)
        (routine: routinesById[entry.key]!, groups: entry.value)
    ];
  }

  Stream<List<GroupEntry>> getNamedGroups(String deviceId) {
    return (select(groups)..where((t) => t.device.equals(deviceId) & t.name.isNotNull() & t.deleted.equals(false))).watch();
  }

  Future<void> upsertRoutine(RoutinesCompanion routine) {
    return transaction(() async {
      final existingEntry = await (select(routines)..where((t) => t.id.equals(routine.id.value))).getSingleOrNull();
      if (existingEntry == null) {
        // don't need to worry about cleaning up removed groups
        await into(routines).insert(routine);
      } else {
        final existingGroups = await (select(groups)..where((t) => t.id.isIn(existingEntry.groups))).get();

        final deleteIds = existingGroups
          .where((g) => g.name == null && !routine.groups.value.any((id) => id == g.id))
          .map((g) => g.id).toList();
        await (update(groups)..where((t) => t.id.isIn(deleteIds))).write(GroupsCompanion(deleted: Value(true), updatedAt: Value(DateTime.now())));

        await (update(routines)..where((t) => t.id.equals(routine.id.value))).write(routine);
      }
    });
  }

  Future<void> upsertGroup(GroupsCompanion group) async {
    await into(groups).insertOnConflictUpdate(group);
  }

  Future<void> tempDeleteDevice(id) async {
    await transaction(() async {
      await (update(groups)..where((t) => t.device.equals(id))).write(GroupsCompanion(deleted: Value(true), updatedAt: Value(DateTime.now()), changes: Value(['deleted'])));
      await (update(devices)..where((t) => t.id.equals(id))).write(DevicesCompanion(deleted: Value(true), updatedAt: Value(DateTime.now()), changes: Value(['deleted'])));
    });
  }
  
  /// Restores groups that were mistakenly deleted with a device
  Future<void> restoreDeviceGroups(String deviceId) async {
    await transaction(() async {
      // Find all groups for this device that are marked as deleted
      final deletedGroups = await (select(groups)..where((t) => t.device.equals(deviceId) & t.deleted.equals(true))).get();
      
      // Restore each group by setting deleted to false
      for (final group in deletedGroups) {
        await (update(groups)..where((t) => t.id.equals(group.id)))
          .write(GroupsCompanion(
            deleted: Value(false),
            updatedAt: Value(DateTime.now()),
            changes: Value([...group.changes, 'deleted']), // Mark 'deleted' as changed
          ));
        
        print('Restored group ${group.id} for device $deviceId');
      }
    });
  }

  Future<void> tempDeleteRoutine(id) async {
    await transaction(() async {
      final routine = await (select(routines)..where((t) => t.id.equals(id))).getSingle();
      await (update(groups)..where((t) => t.id.isIn(routine.groups) & t.name.isNull())).write(GroupsCompanion(deleted: Value(true), changes: Value(['deleted']), updatedAt: Value(DateTime.now())));
      await (update(routines)..where((t) => t.id.equals(id))).write(RoutinesCompanion(deleted: Value(true), changes: Value(['deleted']), updatedAt: Value(DateTime.now())));
    });
  }

  Future<void> deleteRoutine(id) async {
    await (delete(routines)..where((t) => t.id.equals(id))).go();
  }

  Future<List<DeviceEntry>> getDevicesById(List<String> ids) {
    return (select(devices)..where((t) => t.id.isIn(ids))).get();
  }

  Future<void> deleteDevice(String id) async {
    await (delete(devices)..where((t) => t.id.equals(id))).go();
  }

  Future<List<GroupEntry>> getGroupsById(List<String> ids) {
    return (select(groups)..where((t) => t.id.isIn(ids))).get();
  }

  Future<void> tempDeleteGroup(String id) async {
    await transaction(() async {
      await (update(groups)..where((t) => t.id.equals(id))).write(GroupsCompanion(deleted: Value(true), updatedAt: Value(DateTime.now()), changes: Value(['deleted'])));

      final group = await (select(groups)..where((t) => t.id.equals(id))).getSingleOrNull();

      if (group == null) {
        return;
      }

      final groupRoutines = await (select(routines)..where((t) => t.groups.contains(id))).get();

      for (final routine in groupRoutines) {
        upsertGroup(GroupsCompanion(
          id: Value(Uuid().v4()), 
          name: Value(null), 
          allow: Value(group.allow), 
          device: Value(group.device),
          apps: Value(group.apps),
          sites: Value(group.sites),
          changes: Value(group.changes),
          updatedAt: Value(DateTime.now()),
        ));

        await (update(routines)..where((t) => t.id.equals(routine.id))).write(RoutinesCompanion(
          groups: Value([...routine.groups.where((id) => id != group.id), group.id]),
        ));
      }
    });
  }

  Future<void> deleteGroup(id) async {
    await (delete(groups)..where((t) => t.id.equals(id))).go();
  }

  Future<DeviceEntry?> getThisDevice() async {
    return await (select(devices)..where((t) => t.curr.equals(true))).getSingleOrNull();
  }

  Future<void> upsertDevice(DevicesCompanion entry) {
    return into(devices).insertOnConflictUpdate(entry);
  }

  Future<void> updateDevice(DevicesCompanion entry) async {
    await (update(devices)..where((t) => t.id.equals(entry.id.value))).write(entry);
  }

  Future<List<DeviceEntry>> getDevices() {
    return select(devices).get();
  }

  Future<List<RoutineEntry>> getRoutineChanges(DateTime? since) {
    var query = select(routines);
    if (since != null) {
      query.where((t) => t.updatedAt.isBiggerThanValue(since.toUtc()));
    }
    return query.get();
  }

  Future<List<GroupEntry>> getGroupChanges(DateTime? since) {
    var query = select(groups);
    if (since != null) {
      query.where((t) => t.updatedAt.isBiggerThanValue(since.toUtc()));
    }
    return query.get();
  }

  Future<List<DeviceEntry>> getDeviceChanges(DateTime? since) {
    var query = select(devices);
    if (since != null) {
      query.where((t) => t.updatedAt.isBiggerThanValue(since.toUtc()) & (t.changes.isNull() | t.changes.isNotValue('[]')));
    }
    return query.get();
  }

  Future<void> clearChangesSince(DateTime time) async {
    return await transaction(() async {
      await (update(devices)..where((t) => t.updatedAt.isSmallerOrEqualValue(time) & t.deleted.equals(false))).write(DevicesCompanion(changes: Value([])));
      await (delete(devices)..where((t) => t.deleted.equals(true))).go();
      await (update(groups)..where((t) => t.updatedAt.isSmallerOrEqualValue(time) & t.deleted.equals(false))).write(GroupsCompanion(changes: Value([])));
      await (delete(groups)..where((t) => t.deleted.equals(true))).go();
      await (update(routines)..where((t) => t.updatedAt.isSmallerOrEqualValue(time) & t.deleted.equals(false))).write(RoutinesCompanion(changes: Value([])));
      await (delete(routines)..where((t) => t.deleted.equals(true))).go();
    });
  }
}