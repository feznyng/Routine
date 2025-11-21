import 'dart:async';
import 'package:Routine/models/emergency_event.dart';
import 'package:Routine/models/condition.dart';
import 'package:Routine/models/device.dart';
import 'package:Routine/services/auth_service.dart';
import 'package:Routine/util.dart';
import 'package:uuid/uuid.dart';
import '../setup.dart';
import '../database/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'strict_mode_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:synchronized/synchronized.dart';

class SyncJob {
  bool remote;
  bool full;

  SyncJob({required this.remote, this.full = false});
}

class SyncResult {
}

enum SyncStatus {
  success,
  failure,
  notSignedIn
}

class TableChanges {
  List<Map<String, dynamic>> upserts;
  List<String> deletes;

  TableChanges({required this.upserts, required this.deletes});
}

typedef Changes = ({
  TableChanges routines,
  TableChanges groups,
  TableChanges devices
});

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

  Map<String, dynamic> _computeOverwriteMap(dynamic local) {
    if (local == null) return {};
    final map = <String, dynamic>{};
    final localData = local.toJson();
    for (final change in local.changes) {
      if (change == 'new') continue;
      map[change] = localData[change];
    }
    return map;
  }

  DateTime _mergeUpdatedAt(DateTime pulledAt, String remoteUpdatedAt) {
    return pulledAt.toIso8601String().compareTo(remoteUpdatedAt) > 0
        ? pulledAt
        : DateTime.parse(remoteUpdatedAt);
  }

  DateTime _mergeLastPulledAt(DateTime? localLastPulledAt, String remoteLastPulledAt) {
    if (localLastPulledAt == null) return DateTime.parse(remoteLastPulledAt);
    return localLastPulledAt.toIso8601String().compareTo(remoteLastPulledAt) > 0
        ? localLastPulledAt
        : DateTime.parse(remoteLastPulledAt);
  }

  Future<bool> _checkRemoteConflicts(String table, Iterable<String> ids, DateTime pulledAt) async {
    if (ids.isEmpty) return false;
    final records = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .inFilter('id', ids.toList());
    for (final rec in records) {
      if ((rec['updated_at'] as String).compareTo(pulledAt.toUtc().toIso8601String()) > 0) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _syncEmergencyEvents(dynamic userData) async {
    final prefs = await SharedPreferences.getInstance();

    bool madeRemoteChange = false;
    final remoteEvents = <EmergencyEvent>[];
    if (userData['emergencies'] != null) {
      final List<dynamic> eventsList = userData['emergencies'] as List<dynamic>;
      for (final event in eventsList) {
        remoteEvents.add(EmergencyEvent.fromJson(Map<String, dynamic>.from(event)));
      }
    }
    final localEvents = StrictModeService.loadEmergencyEvents(prefs);

    final Map<String, EmergencyEvent> localEventMap = {
      for (final event in localEvents) event.id: event
    };
    final Map<String, EmergencyEvent> remoteEventMap = {
      for (final event in remoteEvents) event.id: event
    };

    final Set<String> allEventIds = {...localEventMap.keys, ...remoteEventMap.keys};
    final List<EmergencyEvent> mergedEvents = [];
    for (final id in allEventIds) {
      final localEvent = localEventMap[id];
      final remoteEvent = remoteEventMap[id];
      if (localEvent != null && remoteEvent != null) {
        localEvent.endedAt = localEvent.endedAt ?? remoteEvent.endedAt;
        mergedEvents.add(localEvent);
      } else if (localEvent != null) {
        mergedEvents.add(localEvent);
      } else if (remoteEvent != null) {
        mergedEvents.add(remoteEvent);
      }
    }

    StrictModeService.cleanEmergencyEvents(mergedEvents);

    mergedEvents.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    if (mergedEvents.isNotEmpty) {
      final latestEvent = mergedEvents.last;
      for (int i = 0; i < mergedEvents.length - 1; i++) {
        final event = mergedEvents[i];
        event.endedAt = event.endedAt ?? latestEvent.startedAt;
      }
    }

    madeRemoteChange = madeRemoteChange || (mergedEvents.length != remoteEvents.length);
    for (final event in mergedEvents) {
      madeRemoteChange = madeRemoteChange 
        || event.startedAt != remoteEventMap[event.id]?.startedAt
        || event.endedAt != remoteEventMap[event.id]?.endedAt;
    }

    logger.i("emergency events: $madeRemoteChange");
    
    await StrictModeService().updateEmergencyEvents(mergedEvents);
    await _client.from('users').update({
      'emergencies': mergedEvents.map((e) => e.toJson()).toList(),
    }).eq('id', userId);

    return madeRemoteChange;
  }

  Future<({bool accidentalDeletion, bool requireFullSync})> _pullDevices(
    AppDatabase db,
    String currDeviceId,
    DateTime lastPulledAt,
    DateTime pulledAt,
  ) async {

    final remoteDevices = await _client
        .from('devices')
        .select()
        .eq('user_id', userId)
        .or('updated_at.gt.${lastPulledAt.toUtc().toIso8601String()},id.eq.$currDeviceId');

    final localDevices = await db.getDevicesById(remoteDevices.map((d) => d['id'] as String).toList());
    final localDeviceMap = {for (final device in localDevices) device.id: device};

    final deviceSyncedBefore = remoteDevices.any((device) => device['id'] == currDeviceId);

    bool accidentalDeletion = false;
    for (final device in remoteDevices) {
      final localDevice = localDeviceMap[device['id']];
      final overwriteMap = _computeOverwriteMap(localDevice);

      final DateTime updatedAt = _mergeUpdatedAt(pulledAt, device['updated_at']);
      final DateTime deviceLastSynced = _mergeLastPulledAt(localDevice?.lastPulledAt, device['last_pulled_at']);

      final isCurrentDevice = localDevice?.curr ?? false;
      final isActiveDevice = device['id'] == currDeviceId;

      if (device['deleted'] as bool && (isCurrentDevice || isActiveDevice)) {
        accidentalDeletion = true;
        await db.upsertDevice(DevicesCompanion(
          id: Value(device['id']),
          name: Value(overwriteMap['name'] ?? device['name']),
          type: Value(overwriteMap['type'] ?? device['type']),
          curr: Value(isCurrentDevice),
          updatedAt: Value(updatedAt),
          lastPulledAt: Value(deviceLastSynced),
          deleted: Value(false),
          changes: Value(['deleted', ...overwriteMap['changes'] ?? const []]),
        ));
      } else if (device['deleted'] as bool) {
        await db.deleteDevice(device['id']);
      } else {
        await db.upsertDevice(DevicesCompanion(
          id: Value(device['id']),
          name: Value(overwriteMap['name'] ?? device['name']),
          type: Value(overwriteMap['type'] ?? device['type']),
          curr: Value(localDevice?.curr ?? false),
          updatedAt: Value(DateTime.now()),
          lastPulledAt: Value(deviceLastSynced),
          deleted: Value(overwriteMap['deleted'] ?? device['deleted']),
          changes: Value(overwriteMap['changes'] ?? const []),
        ));
      }
    }

    return (accidentalDeletion: accidentalDeletion, requireFullSync: !deviceSyncedBefore);
  }

  Future<void> _pullGroups(
    AppDatabase db,
    String currDeviceId,
    DateTime lastPulledAt,
    DateTime pulledAt,
    bool accidentalDeletion,
  ) async {

    final remoteGroups = await _client
        .from('groups')
        .select()
        .eq('user_id', userId)
        .or('updated_at.gt.${lastPulledAt.toUtc().toIso8601String()},id.eq.$currDeviceId');

    final localGroups = await db.getGroupsById(remoteGroups.map((group) => group['id'] as String).toList());
    final localGroupMap = {for (final group in localGroups) group.id: group};

    for (final group in remoteGroups) {
      final overwriteMap = _computeOverwriteMap(localGroupMap[group['id']]);
      final DateTime updatedAt = _mergeUpdatedAt(pulledAt, group['updated_at']);

      if (group['deleted'] as bool) {
        if (group['device'] == currDeviceId && accidentalDeletion) {
          overwriteMap['deleted'] = false;
          overwriteMap['changes'] = ['deleted', ...overwriteMap['changes'] ?? const []];
        } else {
          return await db.deleteGroup(group['id']);
        }
      }

      await db.upsertGroup(GroupsCompanion(
        id: Value(group['id']),
        name: Value(overwriteMap['name'] ?? group['name'] as String?),
        device: Value(overwriteMap['device'] ?? group['device'] as String?),
        allow: Value(overwriteMap['allow'] ?? group['allow'] as bool?),
        updatedAt: Value(updatedAt),
        deleted: Value(overwriteMap['deleted'] ?? group['deleted']),
        changes: Value(overwriteMap['changes'] ?? const [])
      ));
    }
  }

  Future<void> _pullRoutines(
    AppDatabase db,
    DateTime lastPulledAt,
    DateTime pulledAt,
  ) async {
    final remoteRoutines = await _client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastPulledAt.toUtc().toIso8601String());

    final localRoutines = await db.getRoutinesById(remoteRoutines.map((routine) => routine['id'] as String).toList());
    final localRoutineMap = {for (final routine in localRoutines) routine.id: routine};

    for (final routine in remoteRoutines) {
      final overwriteMap = _computeOverwriteMap(localRoutineMap[routine['id']]);
      final DateTime updatedAt = _mergeUpdatedAt(pulledAt, routine['updated_at']);

      final List<Condition> conditions = routine['conditions'] != null
          ? (routine['conditions'] as List<dynamic>).map<Condition>((map) => Condition.fromJson(map)).toList()
          : [];

      final List<Condition> localConditions = localRoutineMap[routine['id']]?.conditions ?? [];
      final Map<String, Condition> localConditionMap = {for (final condition in localConditions) condition.id: condition};

      for (final condition in conditions) {
        final localCondition = localConditionMap[condition.id];
        if (localCondition != null && (condition.lastCompletedAt != null && (localCondition.lastCompletedAt?.isAfter(condition.lastCompletedAt!) ?? false))) {
          condition.lastCompletedAt = localCondition.lastCompletedAt;
        }
      }

      if (routine['deleted'] as bool) {
        await db.deleteRoutine(routine['id']);
      } else {
        await db.upsertRoutine(RoutinesCompanion(
          id: Value(routine['id']),
          name: Value(overwriteMap['name'] ?? routine['name']),
          monday: Value(overwriteMap['monday'] ?? routine['monday']),
          tuesday: Value(overwriteMap['tuesday'] ?? routine['tuesday']),
          wednesday: Value(overwriteMap['wednesday'] ?? routine['wednesday']),
          thursday: Value(overwriteMap['thursday'] ?? routine['thursday']),
          friday: Value(overwriteMap['friday'] ?? routine['friday']),
          saturday: Value(overwriteMap['saturday'] ?? routine['saturday']),
          sunday: Value(overwriteMap['sunday'] ?? routine['sunday']),
          startTime: Value(overwriteMap['start_time'] ?? routine['start_time']),
          endTime: Value(overwriteMap['end_time'] ?? routine['end_time']),
          recurrence: Value(overwriteMap['recurrence'] ?? routine['recurrence']),
          groups: Value(overwriteMap['groups']?.cast<String>() ?? (routine['groups'] as List<dynamic>).cast<String>()),
          numBreaksTaken: Value(overwriteMap['num_breaks_taken'] ?? routine['num_breaks_taken']),
          lastBreakAt: Value(overwriteMap['last_break_at'] != null ? DateTime.parse(overwriteMap['last_break_at']) : routine['last_break_at'] != null ? DateTime.parse(routine['last_break_at']) : null),
          pausedUntil: Value(overwriteMap['paused_until'] != null ? DateTime.parse(overwriteMap['paused_until']) : routine['paused_until'] != null ? DateTime.parse(routine['paused_until']) : null),
          maxBreaks: Value(overwriteMap['max_breaks'] ?? routine['max_breaks']),
          maxBreakDuration: Value(overwriteMap['max_break_duration'] ?? routine['max_break_duration']),
          friction: Value(overwriteMap['friction'] ?? routine['friction']),
          frictionLen: Value(overwriteMap['friction_len'] ?? routine['friction_len']),
          snoozedUntil: Value(overwriteMap['snoozed_until'] != null ? DateTime.parse(overwriteMap['snoozed_until']) : routine['snoozed_until'] != null ? DateTime.parse(routine['snoozed_until']) : null),
          updatedAt: Value(updatedAt),
          deleted: Value(overwriteMap['deleted'] ?? routine['deleted']),
          changes: Value(overwriteMap['changes'] ?? []),
          strictMode: Value((overwriteMap['strictMode'] ?? routine['strict_mode']) ?? false),
          completableBefore: Value((overwriteMap['completableBefore'] ?? routine['completable_before']) ?? 0),
          conditions: Value(conditions),
        ));
      }
    }
  }

  Future<({bool changed, bool conflict})> _pushDevices(
    AppDatabase db,
    DateTime? since,
    DateTime pulledAt,
    String currDeviceId,
  ) async {
    final localDevices = await db.getDeviceChanges(since);
    if (await _checkRemoteConflicts('devices', localDevices.map((d) => d.id), pulledAt)) {
      logger.i("device conflict detected - cancelling sync");
      return (changed: false, conflict: true);
    }

    bool updatedCurrDevice = false;
    final futures = <Future<void>>[];
    for (final device in localDevices) {
      updatedCurrDevice = updatedCurrDevice || device.id == currDeviceId;
      final Map<String, dynamic> data = {
        'id': device.id,
        'user_id': userId,
        'name': device.name,
        'type': device.type,
        'updated_at': device.updatedAt.toUtc().toIso8601String(),
        'last_pulled_at': pulledAt.toUtc().toIso8601String(),
        'deleted': device.deleted,
      };

      futures.add(_client.from('devices').upsert(data).eq('id', device.id));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    if (!updatedCurrDevice) {
      await _client
          .from('devices')
          .update({'last_pulled_at': pulledAt.toUtc().toIso8601String()})
          .eq('id', currDeviceId);
    }

    return (changed: localDevices.isNotEmpty, conflict: false);
  }

  Future<({bool changed, bool conflict})> _pushGroups(
    AppDatabase db,
    DateTime? since,
    DateTime pulledAt,
  ) async {
    final localGroups = await db.getGroupChanges(since);
    if (await _checkRemoteConflicts('groups', localGroups.map((g) => g.id), pulledAt)) {
      logger.i("group conflict detected - cancelling sync");
      return (changed: false, conflict: true);
    }

    final futures = <Future<void>>[];
    for (final group in localGroups) {
      futures.add(_client
          .from('groups')
          .upsert({
            'id': group.id,
            'user_id': userId,
            'name': group.name,
            'device': group.device,
            'allow': group.allow,
            'updated_at': group.updatedAt.toUtc().toIso8601String(),
            'deleted': group.deleted,
          })
          .eq('id', group.id));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    return (changed: localGroups.isNotEmpty, conflict: false);
  }

  Future<({bool changed, bool conflict})> _pushRoutines(
    AppDatabase db,
    DateTime? since,
    DateTime pulledAt,
  ) async {
    final localRoutines = await db.getRoutineChanges(since);
    if (await _checkRemoteConflicts('routines', localRoutines.map((r) => r.id), pulledAt)) {
      logger.i("routine conflict detected - cancelling sync");
      return (changed: false, conflict: true);
    }

    final futures = <Future<void>>[];
    for (final routine in localRoutines) {
      futures.add(_client
          .from('routines')
          .upsert({
            'id': routine.id,
            'user_id': userId,
            'name': routine.name,
            'monday': routine.monday,
            'tuesday': routine.tuesday,
            'wednesday': routine.wednesday,
            'thursday': routine.thursday,
            'friday': routine.friday,
            'saturday': routine.saturday,
            'sunday': routine.sunday,
            'start_time': routine.startTime,
            'end_time': routine.endTime,
            'recurrence': routine.recurrence,
            'groups': routine.groups,
            'conditions': routine.conditions,
            'num_breaks_taken': routine.numBreaksTaken,
            'last_break_at': routine.lastBreakAt?.toUtc().toIso8601String(),
            'paused_until': routine.pausedUntil?.toUtc().toIso8601String(),
            'max_breaks': routine.maxBreaks,
            'max_break_duration': routine.maxBreakDuration,
            'friction': routine.friction,
            'friction_len': routine.frictionLen,
            'snoozed_until': routine.snoozedUntil?.toUtc().toIso8601String(),
            'strict_mode': routine.strictMode,
            'completable_before': routine.completableBefore,
            'updated_at': routine.updatedAt.toUtc().toIso8601String(),
            'deleted': routine.deleted,
          })
          .eq('id', routine.id));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    return (changed: localRoutines.isNotEmpty, conflict: false);
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
            logger.i('received remote sync request from ${payload['source']}');
            await queueSync();
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

  Future<bool> queueSync({bool full = false, bool manual = false}) async {
    if (userId.isEmpty) {
      logger.i("can't sync - user is not signed in");
      if (manual) {
        _syncStatusController.add(SyncStatus.notSignedIn);
      }
      return false;
    }

    return await _syncLock.synchronized(() async {
      if (Util.isDesktop()) {
        _setSyncing(true);
        final success = await sync(full: full);
        _setSyncing(false);
        _syncStatusController.add(success ? SyncStatus.success : SyncStatus.failure);
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
        
        logger.i("queuing up sync: $id");
        await Workmanager().registerOneOffTask("sync", "sync-task", inputData: {'full': full, 'id': id});

        return true;
      }
    });
  }
  
  Future<bool> sync({bool full = false, String? id, bool manual = false}) async {
    if (userId.isEmpty) {
      logger.i("can't sync - user is not signed in");
      if (manual) {
        _syncStatusController.add(SyncStatus.notSignedIn);
      }
      return false;
    }
    
    final stopwatch = Stopwatch();
    stopwatch.start();
    final result = await _sync(full: full);
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

  bool _wasChanged(DateTime now, String? value) {
    if (value == null || value.isEmpty) return true;
    return DateTime.parse(value).isAfter(now);
  }

  void _logElapsedTime(Stopwatch stopwatch, String message) {
    logger.i("$message took ${stopwatch.elapsedMilliseconds}ms");
    stopwatch.reset();
  }

  Future<SyncResult?> _sync({bool full = false}) async {
    try {
      if (userId.isEmpty) {
        logger.i("can't sync - user is not signed in");
        return null;
      }

      final stopwatch = Stopwatch();
      stopwatch.start();
      
      final userData = await _client.from('users')
            .select()
            .eq('id', userId)
            .maybeSingle() ?? 
          await _client.from('users').insert({
            'id': userId,
            'emergencies': []
          }).maybeSingle() as Map<String, dynamic>;

      final pulledAt = DateTime.now();
    
      final routinesChanged = _wasChanged(pulledAt, userData['routines_updated_at']);
      final groupsChanged = _wasChanged(pulledAt, userData['groups_updated_at']);
      final devicesChanged = _wasChanged(pulledAt, userData['devices_updated_at']);
      final usersChanged = _wasChanged(pulledAt, userData['updated_at']);

      _logElapsedTime(stopwatch, 'user fetch');

      if (usersChanged) {
        await _syncEmergencyEvents(userData);
      }

      _logElapsedTime(stopwatch, 'emergency events');

      final db = getIt<AppDatabase>();
      final currDevice = (await db.getThisDevice())!;

      final lastPulledAt = full ? DateTime.fromMicrosecondsSinceEpoch(0) : (currDevice.lastPulledAt ?? DateTime.fromMicrosecondsSinceEpoch(0));

      bool madeRemoteChange = false;
      bool accidentalDeletion = false;

      // pull
      await db.transaction(() async {
        if (devicesChanged) {
          final devicePull = await _pullDevices(db, currDevice.id, lastPulledAt, pulledAt);
          full = full || devicePull.requireFullSync; // if the current device doesn't exist remotely, we need to do a full sync
          accidentalDeletion = devicePull.accidentalDeletion;
          madeRemoteChange = madeRemoteChange || devicePull.requireFullSync;
        }

        final List<Future<dynamic>> pulls = [];
        
        if (groupsChanged) {
          pulls.add(_pullGroups(db, currDevice.id, lastPulledAt, pulledAt, accidentalDeletion));
        }

        if (routinesChanged) {
          pulls.add(_pullRoutines(db, lastPulledAt, pulledAt));
        }

        pulls.add(db.updateDevice(DevicesCompanion(
          id: Value(currDevice.id),
          lastPulledAt: Value(pulledAt),
          updatedAt: Value(pulledAt),
        )));

        await Future.wait(pulls);
      });

      _logElapsedTime(stopwatch, 'pull');
      
      // push
      final results = await Future.wait([
        _pushDevices(db, full ? null : lastPulledAt, pulledAt, currDevice.id),
        _pushGroups(db, full ? null : lastPulledAt, pulledAt),
        _pushRoutines(db, full ? null : lastPulledAt, pulledAt),
      ]);

      _logElapsedTime(stopwatch, 'push');

      final List<String> updatedAtTimes = [
        userData['devices_updated_at'] ?? pulledAt.toUtc().toIso8601String(),
        userData['groups_updated_at'] ?? pulledAt.toUtc().toIso8601String(),
        userData['routines_updated_at'] ?? pulledAt.toUtc().toIso8601String(),
      ];

      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result.conflict) {
          logger.i("conflict");
          // we'll need to try again later so skip clearing changes and notifying external
          return null;
        }
        if (result.changed) {
          madeRemoteChange = true;
          updatedAtTimes[i] = pulledAt.toUtc().toIso8601String();
        }
      }

      await _client.from('users').update({
        'devices_updated_at': updatedAtTimes[0],
        'groups_updated_at': updatedAtTimes[1],
        'routines_updated_at': updatedAtTimes[2],
      }).eq('id', userId);

      _logElapsedTime(stopwatch, 'user update');

      await db.clearChangesSince(pulledAt);
     
      _logElapsedTime(stopwatch, 'local cleanup');
     
      {
        final remoteDevices = (await _client
          .from('devices')
          .select('last_pulled_at')
          .eq('user_id', userId));

        final deviceList = remoteDevices
            .map<String>((d) => d['last_pulled_at'])
            .toList();

        deviceList.sort((a, b) => a.compareTo(b));

        if (deviceList.isNotEmpty) {
          final pulledAt = deviceList[0];

          await Future.wait([
            _client.from('routines').delete().lt('updated_at', pulledAt).eq('deleted', true),
            _client.from('groups').delete().lt('updated_at', pulledAt).eq('deleted', true),
            _client.from('devices').delete().lt('updated_at', pulledAt).eq('deleted', true),
          ]);
        }
      }
      
      _logElapsedTime(stopwatch, 'remote cleanup');
      
      if (madeRemoteChange) {
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
