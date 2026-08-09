import 'package:routine_blocker/database/database.steps.dart';
import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';
import 'string_list_converter.dart';
import '../demo/demo_mode.dart';
import 'package:path_provider/path_provider.dart';
import '../models/condition.dart';
part 'database.g.dart';

@DataClassName('RoutineEntry')
class Routines extends Table {
  late final id = text()();
  late final name = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
  late final monday = boolean()();
  late final tuesday = boolean()();
  late final wednesday = boolean()();
  late final thursday = boolean()();
  late final friday = boolean()();
  late final saturday = boolean()();
  late final sunday = boolean()();
  late final startTime = integer()();
  late final endTime = integer()();
  late final recurrence = integer().clientDefault(() => 1).nullable()();

  late final changes = text().map(StringListTypeConverter())();
  late final deleted = boolean().clientDefault(() => false)();
  late final updatedAt = dateTime()();

  late final groups = text().map(StringListTypeConverter())();
  late final numBreaksTaken = integer().nullable()();
  late final lastBreakAt = dateTime().nullable()();
  late final pausedUntil = dateTime().nullable()();
  late final lastBreakEndedAt = dateTime().nullable()();
  late final maxBreaks = integer().nullable()();
  late final maxBreakDuration = integer().clientDefault(() => 15)();
  late final friction = text()();
  late final frictionLen = integer().nullable()();
  late final snoozedUntil = dateTime().nullable()();

  late final conditions = text().map(const ConditionConverter())();
  late final strictMode = boolean().clientDefault(() => false)();
  late final completableBefore = integer().clientDefault(() => 0).nullable()();
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

  bool _skipUpdates = false;

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.dropColumn(schema.routines, 'recurring');
          await m.addColumn(schema.routines, schema.routines.recurrence);
        },
        from2To3: (m, schema) async {
          await m.addColumn(schema.routines, schema.routines.completableBefore);
        },
        from3To4: (m, schema) async {
          await m.addColumn(schema.routines, schema.routines.lastBreakEndedAt);
        }
      ),
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      // Screenshot builds get their own file. Seeding wipes routines and
      // groups before inserting, and on desktop a debug run shares the
      // installed app's support directory -- pointed at 'routine_db' it would
      // delete the real routines on the machine taking the screenshots.
      name: DemoMode.enabled ? 'routine_db_demo' : 'routine_db',
      native: DriftNativeOptions(
        shareAcrossIsolates: true,
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<List<RoutineEntry>> getRoutinesById(List<String> ids) {
    return (select(routines)..where((t) => t.id.isIn(ids))).get();
  }

  Future<RoutineEntry?> getRoutineById(String id) {
    return (select(routines)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<DateTime?> getLastPulledAt() async {
    final entry = await (select(devices)..where((t) => t.curr.equals(true))).getSingleOrNull();
    return entry?.lastPulledAt;
  }

  Stream<List<DeviceEntry>> watchDevices() {
    return (select(devices)..where((t) => t.deleted.equals(false))).watch().skipWhile((_) => _skipUpdates);
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

    return routineWithGroups.watch().skipWhile((_) {
      return _skipUpdates;
    }).map((rows) {
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

  Future<RoutineEntry?> upsertRoutine(RoutinesCompanion routine) {
    return transaction(() async {
      final existingEntry = await (select(routines)..where((t) => t.id.equals(routine.id.value))).getSingleOrNull();
      if (existingEntry == null) {
        await into(routines).insert(routine);
      } else {
        if (routine.groups.present) {
          final existingGroups = await (select(groups)..where((t) => t.id.isIn(existingEntry.groups))).get();
          final deleteIds = existingGroups
            .where((g) => g.name == null && !routine.groups.value.any((id) => id == g.id))
            .map((g) => g.id).toList();
          await (update(groups)..where((t) => t.id.isIn(deleteIds))).write(GroupsCompanion(deleted: Value(true), updatedAt: Value(DateTime.now())));
        }
        
        await (update(routines)..where((t) => t.id.equals(routine.id.value))).write(routine);

        return await getRoutineById(routine.id.value);
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
  

  Future<void> restoreDeviceGroups(String deviceId) async {
    await transaction(() async {
      final deletedGroups = await (select(groups)..where((t) => t.device.equals(deviceId) & t.deleted.equals(true))).get();
      for (final group in deletedGroups) {
        await (update(groups)..where((t) => t.id.equals(group.id)))
          .write(GroupsCompanion(
            deleted: Value(false),
            updatedAt: Value(DateTime.now()),
            changes: Value([...group.changes, 'deleted']), // Mark 'deleted' as changed
          ));
      }
    });
  }

  Future<void> tempDeleteRoutine(String id) async {
    await transaction(() async {
      final routine = await (select(routines)..where((t) => t.id.equals(id))).getSingle();
      await (update(groups)..where((t) => t.id.isIn(routine.groups) & t.name.isNull())).write(GroupsCompanion(deleted: Value(true), changes: Value(['deleted']), updatedAt: Value(DateTime.now())));
      await (update(routines)..where((t) => t.id.equals(id))).write(RoutinesCompanion(deleted: Value(true), changes: Value(['deleted']), updatedAt: Value(DateTime.now())));
    });
  }

  Future<void> deleteRoutine(String id) async {
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

  Future<GroupEntry?> getGroupById(String id) {
    return (select(groups)..where((t) => t.id.equals(id))).getSingleOrNull();
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

  // The complete local state, tombstones included -- this is what gets posted
  // to sync_snapshot.
  Future<List<GroupEntry>> getAllGroups() => select(groups).get();
  Future<List<RoutineEntry>> getAllRoutines() => select(routines).get();

  /// Replaces local state with the merged snapshot returned by sync_snapshot.
  ///
  /// Two things this deliberately does NOT do:
  ///
  /// It does not touch columns that exist only on the client -- `devices.curr`,
  /// `groups.apps/sites/categories`, `routines.lastBreakEndedAt`. Those are
  /// omitted from the update companions so an upsert leaves them alone, and are
  /// only given values when inserting a row that does not exist yet.
  ///
  /// It does not touch rows edited while the sync was in flight. The `sent*`
  /// maps carry each row's `updatedAt` as it was when the payload was built; if
  /// the stored value no longer matches, the row was written during the round
  /// trip and is left alone, dirty flags intact, for the next sync to carry.
  /// This is an exact version check rather than a clock comparison -- rows come
  /// back stamped with the server's clock, so comparing against local time
  /// would misfire under skew. Under full sync a deferred row costs one cycle;
  /// the old incremental path lost the write permanently.
  ///
  /// Deletes are confined to ids that were actually sent. A row created locally
  /// after the payload was built is absent from the response simply because the
  /// server never saw it, and must not be mistaken for a remote delete.
  Future<void> applySyncSnapshot({
    required Map<String, DateTime> sentDevices,
    required Map<String, DateTime> sentGroups,
    required Map<String, DateTime> sentRoutines,
    required List<DevicesCompanion> mergedDevices,
    required List<GroupsCompanion> mergedGroups,
    required List<RoutinesCompanion> mergedRoutines,
  }) async {
    _skipUpdates = true;
    try {
      await transaction(() async {
        final localDevices = {for (final d in await select(devices).get()) d.id: d};
        final localGroups = {for (final g in await select(groups).get()) g.id: g};
        final localRoutines = {for (final r in await select(routines).get()) r.id: r};

        // A row is safe to overwrite only if it still holds the exact version
        // we sent. Absent locally means it is new to us, which is also safe.
        bool touchedDuringSync(DateTime? localUpdatedAt, DateTime? sentUpdatedAt) =>
            localUpdatedAt != null && localUpdatedAt != sentUpdatedAt;

        // Devices before groups: groups.device references devices.id.
        for (final entry in mergedDevices) {
          final id = entry.id.value;
          final local = localDevices[id];
          if (touchedDuringSync(local?.updatedAt, sentDevices[id])) continue;
          if (local == null) {
            await into(devices).insert(entry.copyWith(curr: const Value(false)));
          } else {
            await (update(devices)..where((t) => t.id.equals(id))).write(entry);
          }
        }

        for (final entry in mergedGroups) {
          final id = entry.id.value;
          final local = localGroups[id];
          if (touchedDuringSync(local?.updatedAt, sentGroups[id])) continue;
          if (local == null) {
            await into(groups).insert(entry);
          } else {
            await (update(groups)..where((t) => t.id.equals(id))).write(entry);
          }
        }

        for (final entry in mergedRoutines) {
          final id = entry.id.value;
          final local = localRoutines[id];
          if (touchedDuringSync(local?.updatedAt, sentRoutines[id])) continue;
          if (local == null) {
            await into(routines).insert(entry);
          } else {
            await (update(routines)..where((t) => t.id.equals(id))).write(entry);
          }
        }

        // Anything we sent that did not come back was deleted remotely -- but
        // only drop it if it still holds the version we sent.
        Set<String> dropped(
          Map<String, DateTime> sent,
          Set<String> kept,
          Map<String, dynamic> local,
        ) {
          return sent.keys
              .where((id) => !kept.contains(id))
              .where((id) => !touchedDuringSync(local[id]?.updatedAt, sent[id]))
              .toSet();
        }

        final dropRoutines = dropped(
            sentRoutines, mergedRoutines.map((r) => r.id.value).toSet(), localRoutines);
        final dropGroups = dropped(
            sentGroups, mergedGroups.map((g) => g.id.value).toSet(), localGroups);
        final dropDevices = dropped(
            sentDevices, mergedDevices.map((d) => d.id.value).toSet(), localDevices);

        if (dropRoutines.isNotEmpty) {
          await (delete(routines)..where((t) => t.id.isIn(dropRoutines))).go();
        }
        if (dropGroups.isNotEmpty) {
          await (delete(groups)..where((t) => t.id.isIn(dropGroups))).go();
        }
        // Never drop this device's own row out from under the running app.
        final selfRemoved = dropDevices.where((id) => localDevices[id]?.curr != true).toSet();
        if (selfRemoved.isNotEmpty) {
          await (delete(devices)..where((t) => t.id.isIn(selfRemoved))).go();
        }
      });
    } finally {
      _skipUpdates = false;
    }
  }

  Future<void> forceNotifyChanges() async {
    notifyUpdates({TableUpdate.onTable(routines, kind: UpdateKind.insert)});
    notifyUpdates({TableUpdate.onTable(devices, kind: UpdateKind.insert)});
  }
}