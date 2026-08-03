import 'dart:async';
import 'package:routine_blocker/models/emergency_event.dart';
import 'package:routine_blocker/models/condition.dart';
import 'package:routine_blocker/models/device.dart';
import 'package:routine_blocker/services/auth_service.dart';
import 'package:routine_blocker/util.dart';
import 'package:uuid/uuid.dart';
import '../setup.dart';
import '../database/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'strict_mode_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:synchronized/synchronized.dart';

class SyncResult {
}

enum SyncStatus {
  success,
  failure,
  notSignedIn
}

/// Maps a locally-tracked dirty field to the remote column it corresponds to.
///
/// The models record dirty fields using Dart property names; sync_snapshot
/// overlays them by column name. Keys absent from these maps are dropped, which
/// is what happens to the 'new' marker and to the group content fields
/// (apps/sites/categories), which have no remote column and so do not sync.
const Map<String, String> _routineFields = {
  'name': 'name',
  'monday': 'monday',
  'tuesday': 'tuesday',
  'wednesday': 'wednesday',
  'thursday': 'thursday',
  'friday': 'friday',
  'saturday': 'saturday',
  'sunday': 'sunday',
  'startTime': 'start_time',
  'endTime': 'end_time',
  'recurrence': 'recurrence',
  'groups': 'groups',
  'conditions': 'conditions',
  'numBreaksTaken': 'num_breaks_taken',
  'lastBreakAt': 'last_break_at',
  'pausedUntil': 'paused_until',
  'snoozedUntil': 'snoozed_until',
  'maxBreaks': 'max_breaks',
  'maxBreakDuration': 'max_break_duration',
  'friction': 'friction',
  'frictionLen': 'friction_len',
  'strictMode': 'strict_mode',
  'completableBefore': 'completable_before',
  'deleted': 'deleted',
};

const Map<String, String> _groupFields = {
  'name': 'name',
  'allow': 'allow',
  'deleted': 'deleted',
};

const Map<String, String> _deviceFields = {
  'name': 'name',
  'deleted': 'deleted',
};

class SyncService {
  static final SyncService _instance = SyncService._internal();
  final SupabaseClient _client;
  RealtimeChannel? _syncChannel;
  Timer? _syncStatusPollingTimer;
  String? _latestSyncJobId;
  final Lock _syncLock = Lock();

  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  final StreamController<bool> _syncingController = StreamController<bool>.broadcast();

  String get userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  SyncService._internal() :
    _client = Supabase.instance.client {
    setupRealtimeSync();
  }

  factory SyncService() {
    return _instance;
  }

  Stream<SyncStatus> get onSyncStatus => _syncStatusController.stream;
  Stream<bool> get isSyncing => _syncingController.stream;

  void _setSyncing(bool value) {
    try {
      _syncingController.add(value);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Snapshot serialization
  // ---------------------------------------------------------------------------

  List<String> _remoteChanges(List<String> changes, Map<String, String> fields) {
    return changes.map((c) => fields[c]).whereType<String>().toSet().toList();
  }

  Map<String, dynamic> _deviceRow(DeviceEntry d) => {
    'id': d.id,
    'name': d.name,
    'type': d.type,
    'deleted': d.deleted,
    'updated_at': d.updatedAt.toUtc().toIso8601String(),
    'changes': _remoteChanges(d.changes, _deviceFields),
  };

  Map<String, dynamic> _groupRow(GroupEntry g) => {
    'id': g.id,
    'name': g.name,
    'device': g.device,
    'allow': g.allow,
    'deleted': g.deleted,
    'updated_at': g.updatedAt.toUtc().toIso8601String(),
    'changes': _remoteChanges(g.changes, _groupFields),
  };

  Map<String, dynamic> _routineRow(RoutineEntry r) => {
    'id': r.id,
    'name': r.name,
    'monday': r.monday,
    'tuesday': r.tuesday,
    'wednesday': r.wednesday,
    'thursday': r.thursday,
    'friday': r.friday,
    'saturday': r.saturday,
    'sunday': r.sunday,
    'start_time': r.startTime,
    'end_time': r.endTime,
    'recurrence': r.recurrence,
    'groups': r.groups,
    'conditions': r.conditions.map((c) => c.toJson()).toList(),
    'num_breaks_taken': r.numBreaksTaken,
    'last_break_at': r.lastBreakAt?.toUtc().toIso8601String(),
    'paused_until': r.pausedUntil?.toUtc().toIso8601String(),
    'max_breaks': r.maxBreaks,
    'max_break_duration': r.maxBreakDuration,
    'friction': r.friction,
    'friction_len': r.frictionLen,
    'snoozed_until': r.snoozedUntil?.toUtc().toIso8601String(),
    'strict_mode': r.strictMode,
    'completable_before': r.completableBefore,
    'updated_at': r.updatedAt.toUtc().toIso8601String(),
    'deleted': r.deleted,
    'changes': _remoteChanges(r.changes, _routineFields),
  };

  // ---------------------------------------------------------------------------
  // Snapshot deserialization
  // ---------------------------------------------------------------------------

  DateTime? _asDate(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();

  // The live type of routines.recurrence is not pinned down (setup.sql declares
  // it boolean, the client has always written an integer), so accept either.
  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is bool) return v ? 1 : 0;
    return int.tryParse('$v');
  }

  /// Per-condition completion times are merged client-side: `conditions` is a
  /// single JSONB column remotely, so the server can only take one side whole.
  /// A newer local completion wins and is re-marked dirty so it propagates on
  /// the next sync.
  ({List<Condition> conditions, bool localWon}) _mergeConditions(
    List<Condition> remote,
    List<Condition>? local,
  ) {
    if (local == null || local.isEmpty) return (conditions: remote, localWon: false);

    final localById = {for (final c in local) c.id: c};
    bool localWon = false;

    for (final condition in remote) {
      final localCondition = localById[condition.id];
      final localCompleted = localCondition?.lastCompletedAt;
      if (localCompleted == null) continue;

      if (condition.lastCompletedAt == null || localCompleted.isAfter(condition.lastCompletedAt!)) {
        condition.lastCompletedAt = localCompleted;
        localWon = true;
      }
    }

    return (conditions: remote, localWon: localWon);
  }

  DevicesCompanion _deviceCompanion(Map<String, dynamic> row) => DevicesCompanion(
    id: Value(row['id'] as String),
    name: Value(row['name'] as String),
    type: Value(row['type'] as String),
    deleted: const Value(false),
    updatedAt: Value(_asDate(row['updated_at'])!),
    lastPulledAt: Value(_asDate(row['last_pulled_at'])),
    changes: const Value([]),
  );

  GroupsCompanion _groupCompanion(Map<String, dynamic> row) => GroupsCompanion(
    id: Value(row['id'] as String),
    name: Value(row['name'] as String?),
    device: Value(row['device'] as String),
    allow: Value(row['allow'] as bool),
    deleted: const Value(false),
    updatedAt: Value(_asDate(row['updated_at'])!),
    changes: const Value([]),
  );

  RoutinesCompanion _routineCompanion(Map<String, dynamic> row, RoutineEntry? local) {
    final remoteConditions = (row['conditions'] as List<dynamic>? ?? [])
        .map<Condition>((c) => Condition.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    final merged = _mergeConditions(remoteConditions, local?.conditions);

    return RoutinesCompanion(
      id: Value(row['id'] as String),
      name: Value(row['name'] as String),
      monday: Value(row['monday'] as bool),
      tuesday: Value(row['tuesday'] as bool),
      wednesday: Value(row['wednesday'] as bool),
      thursday: Value(row['thursday'] as bool),
      friday: Value(row['friday'] as bool),
      saturday: Value(row['saturday'] as bool),
      sunday: Value(row['sunday'] as bool),
      startTime: Value(row['start_time'] as int),
      endTime: Value(row['end_time'] as int),
      recurrence: Value(_asInt(row['recurrence'])),
      groups: Value((row['groups'] as List<dynamic>).cast<String>()),
      conditions: Value(merged.conditions),
      numBreaksTaken: Value(row['num_breaks_taken'] as int?),
      lastBreakAt: Value(_asDate(row['last_break_at'])),
      pausedUntil: Value(_asDate(row['paused_until'])),
      maxBreaks: Value(row['max_breaks'] as int?),
      maxBreakDuration: Value(row['max_break_duration'] as int),
      friction: Value(row['friction'] as String),
      frictionLen: Value(row['friction_len'] as int?),
      snoozedUntil: Value(_asDate(row['snoozed_until'])),
      strictMode: Value((row['strict_mode'] as bool?) ?? false),
      completableBefore: Value((row['completable_before'] as int?) ?? 0),
      deleted: const Value(false),
      updatedAt: Value(_asDate(row['updated_at'])!),
      changes: Value(merged.localWon ? const ['conditions'] : const []),
    );
  }

  /// "Start of this week" is a local-timezone notion, so the cutoff is computed
  /// here and sent as an absolute instant for the server to apply.
  DateTime _emergencyPruneCutoff() {
    final now = DateTime.now();
    final daysSinceSunday = now.weekday % 7; // Mon=1..Sun=7 -> 0 on Sunday
    final localMidnight = DateTime(now.year, now.month, now.day);
    return localMidnight.subtract(Duration(days: daysSinceSunday));
  }

  void setupRealtimeSync() {
    if (userId.isEmpty) return;

    _syncChannel?.unsubscribe();

    try {
      _syncChannel = _client.channel('sync-$userId');

      _syncChannel!
        .onBroadcast(
          event: 'sync',
          callback: (payload, [_]) async {
            await queueSync('remote_sync');
          }
        )
        .onBroadcast(
          event: 'sign-out',
          callback: (payload, [_]) {
            logger.i('received remote sign out event');
            AuthService().signOut(forced: true);
          }
        )
        .subscribe();
    } catch (e, st) {
      Util.report('error setting up real time sync', e, st);
    }
  }

  Future<void> _sendRealtimeMessage(String type) async {
    final currDevice = await Device.getCurrent();

    try {
      final channel = _syncChannel;
      if (channel != null) {
        await channel.sendBroadcastMessage(
          event: type,
          payload: { 'timestamp': DateTime.now().toIso8601String(), 'source': currDevice.id },
        );
      }
    } catch (e, st) {
      Util.report('error websocket notifying other devices', e, st);
      setupRealtimeSync();
    }
  }

  Future<void> _notifyPeers() async {
    final currDevice = await Device.getCurrent();

    logger.i("notifying peers");

    await _sendRealtimeMessage('sync');

    try {
      await _client.functions.invoke('push', body: {'source_id': currDevice.id});
    } catch (e, st) {
      Util.report('error fcm notifying other devices', e, st);
    }
  }

  Future<void> notifyPeersSignOut() async {
    await _sendRealtimeMessage('sign-out');
  }

  Future<void> dispose() async {
    await _syncChannel?.unsubscribe();
    _stopSyncStatusPolling();
    await _syncStatusController.close();
    await _syncingController.close();
  }

  Future<bool> queueSync(String source, {bool manual = false}) async {
    if (userId.isEmpty) {
      logger.i("can't sync - user is not signed in");
      if (manual) {
        _syncStatusController.add(SyncStatus.notSignedIn);
      }
      return false;
    }

    logger.i("queuing up sync for $source");

    return await _syncLock.synchronized(() async {
      if (Util.isDesktop()) {
        _setSyncing(true);
        sync().then((success) {
          _syncStatusController.add(success ? SyncStatus.success : SyncStatus.failure);
          _setSyncing(false);
        });

        return true;
      } else  {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        final syncStatusKeys = allKeys.where((key) => key.startsWith('sync_job_status_'));

        for (final key in syncStatusKeys) {
          await prefs.remove(key);
        }
        final id = Uuid().v4();
        _latestSyncJobId = id;
        await prefs.remove('sync_job_status_$id');
        _startSyncStatusPolling();
        _setSyncing(true);

        await Workmanager().registerOneOffTask("sync", "sync-task", inputData: {'id': id});

        return true;
      }
    });
  }

  Future<bool> sync({String? id, bool manual = false}) async {
    if (userId.isEmpty) {
      logger.i("can't sync - user is not signed in");
      if (manual) {
        _syncStatusController.add(SyncStatus.notSignedIn);
      }
      return false;
    }

    final stopwatch = Stopwatch();
    stopwatch.start();
    final result = await _sync();
    logger.i('sync took ${stopwatch.elapsedMilliseconds}ms');

    final success = result != null;
    logger.i("finished syncing - success = $success");

    if (id != null) {
      final key = 'sync_job_status_$id';
      await SharedPreferencesAsync().setBool(key, success);
    }

    return success;
  }

  void _startSyncStatusPolling() {
    _stopSyncStatusPolling();
    _syncStatusPollingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      await _checkSyncStatusChanges();
    });
  }

  void _stopSyncStatusPolling() {
    if (_syncStatusPollingTimer != null) {
      _syncStatusPollingTimer!.cancel();
      _syncStatusPollingTimer = null;
    }
  }

  Future<void> _checkSyncStatusChanges() async {
    try {
      if (_latestSyncJobId == null) {
        _stopSyncStatusPolling();
        return;
      }

      final prefs = SharedPreferencesAsync();
      final key = 'sync_job_status_$_latestSyncJobId';

      final currentStatus = await prefs.getBool(key);

      if (currentStatus == null) {
        return;
      }

      final db = getIt<AppDatabase>();
      await db.forceNotifyChanges();
      await StrictModeService().reloadEmergencyEvents();

      _stopSyncStatusPolling();
      _syncStatusController.add(currentStatus ? SyncStatus.success : SyncStatus.failure);
      _setSyncing(false);

    } catch (e, st) {
      Util.report('error checking sync status changes', e, st);
    }
  }

  void _logElapsedTime(Stopwatch stopwatch, String message) {
    logger.i("$message took ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.reset();
  }

  /// Posts the entire local snapshot to sync_snapshot, which merges it against
  /// stored state in a single transaction and returns the merged result. That
  /// result becomes the new local state.
  Future<SyncResult?> _sync() async {
    try {
      if (userId.isEmpty) {
        logger.i("can't sync - user is not signed in");
        return null;
      }

      final stopwatch = Stopwatch();
      stopwatch.start();

      final db = getIt<AppDatabase>();
      final currDevice = await db.getThisDevice();
      if (currDevice == null) {
        logger.i("can't sync - no current device");
        return null;
      }

      final prefs = await SharedPreferences.getInstance();

      final localDevices = await db.getDevices();
      final localGroups = await db.getAllGroups();
      final localRoutines = await db.getAllRoutines();
      final localRoutinesById = {for (final r in localRoutines) r.id: r};

      final payload = <String, dynamic>{
        'device_id': currDevice.id,
        'devices': localDevices.map(_deviceRow).toList(),
        'groups': localGroups.map(_groupRow).toList(),
        'routines': localRoutines.map(_routineRow).toList(),
        'emergencies': StrictModeService.loadEmergencyEvents(prefs)
            .map((e) => e.toJson())
            .toList(),
        'prune_emergencies_before': _emergencyPruneCutoff().toUtc().toIso8601String(),
      };

      _logElapsedTime(stopwatch, 'snapshot build');

      final raw = await _client.rpc('sync_snapshot', params: {'payload': payload});
      final response = Map<String, dynamic>.from(raw as Map);

      _logElapsedTime(stopwatch, 'rpc');

      if (response['reset'] == true) {
        logger.i("sync reset - this device was stale beyond the tombstone window");
      }

      final devices = (response['devices'] as List<dynamic>)
          .map((r) => _deviceCompanion(Map<String, dynamic>.from(r)))
          .toList();
      final groups = (response['groups'] as List<dynamic>)
          .map((r) => _groupCompanion(Map<String, dynamic>.from(r)))
          .toList();
      final routines = (response['routines'] as List<dynamic>).map((r) {
        final row = Map<String, dynamic>.from(r);
        return _routineCompanion(row, localRoutinesById[row['id']]);
      }).toList();

      // Row versions as they were when the payload was built, so the apply can
      // tell which rows were written during the round trip and defer them.
      await db.applySyncSnapshot(
        sentDevices: {for (final d in localDevices) d.id: d.updatedAt},
        sentGroups: {for (final g in localGroups) g.id: g.updatedAt},
        sentRoutines: {for (final r in localRoutines) r.id: r.updatedAt},
        mergedDevices: devices,
        mergedGroups: groups,
        mergedRoutines: routines,
      );

      final events = (response['emergencies'] as List<dynamic>)
          .map((e) => EmergencyEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await StrictModeService().updateEmergencyEvents(events);

      _logElapsedTime(stopwatch, 'apply');

      if (response['changed'] == true) {
        logger.i("made remote change");
        await _notifyPeers();
      }

      _logElapsedTime(stopwatch, 'remote notify');

      return SyncResult();
    } catch (e, st) {
      Util.report('error syncing', e, st);
      return null;
    }
  }
}
