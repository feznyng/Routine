import 'dart:async';
import 'dart:convert';
import 'package:Routine/condition.dart';

import 'setup.dart';
import 'database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';

class SyncJob {
  bool remote;

  SyncJob({required this.remote});
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
  RealtimeChannel? _syncChannel;
  
  SyncService._internal() {
    _startConsumer();
    setupRealtimeSync();
  }
  
  factory SyncService() {
    return _instance;
  }

  void setupRealtimeSync() {
    final userId = _userId;
    if (userId.isEmpty) return;

    // Clean up existing subscription if any
    _syncChannel?.unsubscribe();

    // Subscribe to sync channel for this user
    _syncChannel = _client.channel('sync-$userId');

    _syncChannel!
      .onBroadcast( 
        event: 'sync', 
        callback: (payload, [_]) {
          addJob(SyncJob(remote: true));
        }
      )
      .subscribe();
  }

  Future<void> _notifyPeers() async {
    final channel = _syncChannel;
    if (channel == null) return;

    await channel.sendBroadcastMessage(
      event: 'sync',
      payload: { 'timestamp': DateTime.now().toIso8601String() },
    );
  }
  
  final _jobController = StreamController<SyncJob>();
  Timer? _batchTimer;
  final List<SyncJob> _pendingJobs = [];
  bool _isProcessing = false;
  final SupabaseClient _client = Supabase.instance.client;

  
  void addJob(SyncJob job) {
    _jobController.add(job);
  }
  
  void _startConsumer() {
    _jobController.stream.listen((job) {
      _pendingJobs.add(job);
      _scheduleBatchProcessing();
    });
  }
  
  void _scheduleBatchProcessing() {
    _batchTimer?.cancel();
    
    _batchTimer = Timer(Duration(milliseconds: 100), () {
      if (!_isProcessing) {
        _processJobs();
      }
    });
  }
  
  Future<void> _processJobs() async {
    if (_isProcessing || _pendingJobs.isEmpty) return;
    
    _isProcessing = true;
    
    try {
      final batchJobs = List<SyncJob>.from(_pendingJobs);
      _pendingJobs.clear();
      
      if (batchJobs.isNotEmpty) {
        await _sync(batchJobs.any((job) => !job.remote));
      }
    } finally {
      _isProcessing = false;
      
      if (_pendingJobs.isNotEmpty) {
        _scheduleBatchProcessing();
      }
    }
  }
  
  Future<void> dispose() async {
    _batchTimer?.cancel();
    await _syncChannel?.unsubscribe();
    _jobController.close();
  }

  String get _userId => _client.auth.currentUser?.id ?? '';

  // order matters: devices, groups, routines
  Future<bool> _sync(bool notifyRemote) async {

    
    if (_userId.isEmpty) return true;
    
    final db = getIt<AppDatabase>();
    final currDevice = (await db.getThisDevice())!;
    final lastPulledAt = currDevice.lastPulledAt ?? DateTime.fromMicrosecondsSinceEpoch(0);
    final pulledAt = DateTime.now();

    // Pull and apply remote device changes
    {
      final remoteDevices = await _client.from('devices').select().eq('user_id', _userId).gt('updated_at', lastPulledAt.toUtc().toIso8601String());

     
      final localDevices = await db.getDevicesById(remoteDevices.map((device) => device['id'] as String).toList());
      final localDeviceMap = {for (final device in localDevices) device.id: device};
      for (final device in remoteDevices) {
        final overwriteMap = {};
        final localDevice = localDeviceMap[device['id']];

        if (localDevice != null) {
          final localDeviceData = localDevice.toJson();
          for (final change in localDevice.changes) {
            overwriteMap[change] = localDeviceData[change];
          }
        }

        final DateTime updatedAt = localDevice != null && localDevice.updatedAt.toIso8601String().compareTo(device['updated_at']) > 0 ? localDevice.updatedAt : DateTime.parse(device['updated_at']);

        if (device['deleted'] as bool) {
          db.deleteDevice(device['id']);
        } else {
           db.upsertDevice(DevicesCompanion(
            id: Value(device['id']),
            name: Value(overwriteMap['name'] ?? device['name']),
            type: Value(overwriteMap['type'] ?? device['type']),
            curr: Value(localDevice?.curr ?? false),
            updatedAt: Value(updatedAt),
            deleted: Value(overwriteMap['deleted'] ?? device['deleted']),
            changes: Value(overwriteMap['changes'] ?? const []),
          ));
        }
      }
    }

    // Pull and apply remote group changes
    {
      final remoteGroups = await _client.from('groups').select().eq('user_id', _userId).gt('updated_at', lastPulledAt.toUtc().toIso8601String());

     
      final localGroups = await db.getGroupsById(remoteGroups.map((group) => group['id'] as String).toList());
      final localGroupMap = {for (final group in localGroups) group.id: group};
      
      for (final group in remoteGroups) {
        final overwriteMap = {};
        final localGroup = localGroupMap[group['id']];

        if (localGroup != null) {
          final localGroupData = localGroup.toJson();
          for (final change in localGroup.changes) {
            overwriteMap[change] = localGroupData[change];
          }
        }

        final DateTime updatedAt = localGroup != null && localGroup.updatedAt.toIso8601String().compareTo(group['updated_at']) > 0 ? localGroup.updatedAt : DateTime.parse(group['updated_at']);

        if (group['deleted'] as bool) {
          db.deleteGroup(group['id']);
        } else {
          db.upsertGroup(GroupsCompanion(
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
    }

    // Pull and apply remote routine changes
    {
      final remoteRoutines = await _client.from('routines').select().eq('user_id', _userId).gt('updated_at', lastPulledAt.toUtc().toIso8601String());
     
      final localRoutines = await db.getRoutinesById(remoteRoutines.map((routine) => routine['id'] as String).toList());
      final localRoutineMap = {for (final routine in localRoutines) routine.id: routine};
      
      for (final routine in remoteRoutines) {
        final overwriteMap = {};
        final localRoutine = localRoutineMap[routine['id']];

        if (localRoutine != null) {
          final localRoutineData = localRoutine.toJson();
          for (final change in localRoutine.changes) {
            overwriteMap[change] = localRoutineData[change];
          }
        }

        final DateTime updatedAt = localRoutine != null && localRoutine.updatedAt.toIso8601String().compareTo(routine['updated_at']) > 0 ? localRoutine.updatedAt : DateTime.parse(routine['updated_at']);
        
        final List<Condition> conditions = routine['conditions'] != null ? 
          json.decode(routine['conditions'] as String).map<Condition>((map) => Condition.fromJson(Map<String, dynamic>.from(map))).toList() : [];

        final List<Condition> localConditions = localRoutine?.conditions ?? [];
        final Map<String, Condition> localConditionMap = {for (final condition in localConditions) condition.id: condition};

        for (final condition in conditions) {
          final localCondition = localConditionMap[condition.id];
          if (localCondition != null && (condition.lastCompletedAt != null && (localCondition.lastCompletedAt?.isAfter(condition.lastCompletedAt!) ?? false))) {
            condition.lastCompletedAt = localCondition.lastCompletedAt;
          }
        }
        
        if (routine['deleted'] as bool) {
          db.deleteRoutine(routine['id']);
        } else {
          db.upsertRoutine(RoutinesCompanion( 
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
            recurring: Value(overwriteMap['recurring'] ?? routine['recurring']),
            groups: Value(overwriteMap['groups']?.cast<String>() ?? (routine['groups'] as List<dynamic>).cast<String>()),
            numBreaksTaken: Value(overwriteMap['num_breaks_taken'] ?? routine['num_breaks_taken']),
            lastBreakAt: Value(overwriteMap['last_break_at'] != null ? DateTime.parse(overwriteMap['last_break_at']) : routine['last_break_at'] != null ? DateTime.parse(routine['last_break_at']) : null),
            pausedUntil: Value(overwriteMap['paused_until'] != null ? DateTime.parse(overwriteMap['paused_until']) : routine['paused_until'] != null ? DateTime.parse(routine['paused_until']) : null),
            maxBreaks: Value(overwriteMap['max_breaks'] ?? routine['max_breaks']),
            maxBreakDuration: Value(overwriteMap['max_break_duration'] ?? routine['max_break_duration']),
            friction: Value(FrictionType.values.byName(overwriteMap['friction'] ?? routine['friction'])),
            frictionLen: Value(overwriteMap['friction_len'] ?? routine['friction_len']),
            snoozedUntil: Value(overwriteMap['snoozed_until'] != null ? DateTime.parse(overwriteMap['snoozed_until']) : routine['snoozed_until'] != null ? DateTime.parse(routine['snoozed_until']) : null),
            updatedAt: Value(updatedAt),
            deleted: Value(overwriteMap['deleted'] ?? routine['deleted']),
            changes: Value(overwriteMap['changes'] ?? []),
            conditions: Value(conditions),
          ));
        }
      }
    }

    db.updateDevice(DevicesCompanion(
      id: Value(currDevice.id),
      lastPulledAt: Value(pulledAt),
      updatedAt: Value(pulledAt),
    ));

    // Push local device changes if no conflicts
    {
      final localDevices = await db.getDeviceChanges(lastPulledAt);

      final remoteDevices = await _client
        .from('devices')
        .select()
        .eq('user_id', _userId)
        .inFilter('id', localDevices.map((device) => device.id).toList());
      final remoteDeviceMap = {for (final device in remoteDevices) device['id']: device};
      for (final device in localDevices) {
        final remoteDevice = remoteDeviceMap[device.id];
        if (remoteDevice != null && remoteDevice['updated_at'].compareTo(pulledAt.toUtc().toIso8601String()) > 0) {

          return false;
        }
      }

      for (final device in localDevices) {
        await _client
        .from('devices')
        .upsert({
          'id': device.id, 
          'user_id': _userId,
          'name': device.name,
          'type': device.type,
          'updated_at': device.updatedAt.toUtc().toIso8601String(),
          'last_pulled_at': pulledAt.toUtc().toIso8601String(),
          'deleted': device.deleted,
        })
        .eq('id', device.id);
      }
    }

    // Push local group changes if no conflicts
    {
      final localGroups = await db.getGroupChanges(lastPulledAt);

      final remoteGroups = await _client
        .from('groups')
        .select()
        .eq('user_id', _userId)
        .inFilter('id', localGroups.map((group) => group.id).toList());
      final remoteGroupMap = {for (final group in remoteGroups) group['id']: group};
      
      for (final group in localGroups) {
        final remoteGroup = remoteGroupMap[group.id];
        if (remoteGroup != null && remoteGroup['updated_at'].compareTo(pulledAt.toUtc().toIso8601String()) > 0) {

          return false;
        }
      }

      for (final group in localGroups) {
        await _client
        .from('groups')
        .upsert({
          'id': group.id,
          'user_id': _userId,
          'name': group.name,
          'device': group.device,
          'allow': group.allow,
          'updated_at': group.updatedAt.toUtc().toIso8601String(),
          'deleted': group.deleted,
        })
        .eq('id', group.id);
      }
    }

    // Push local routine changes if no conflicts
    {
      final localRoutines = await db.getRoutineChanges(lastPulledAt);

      final remoteRoutines = await _client
        .from('routines')
        .select()
        .eq('user_id', _userId)
        .inFilter('id', localRoutines.map((routine) => routine.id).toList());
      final remoteRoutineMap = {for (final routine in remoteRoutines) routine['id']: routine};
      
      for (final routine in localRoutines) {
        final remoteRoutine = remoteRoutineMap[routine.id];
        if (remoteRoutine != null && remoteRoutine['updated_at'].compareTo(pulledAt.toUtc().toIso8601String()) > 0) {

          return false;
        }
      }

      for (final routine in localRoutines) {


        await _client
        .from('routines')
        .upsert({
          'id': routine.id,
          'user_id': _userId,
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
          'recurring': routine.recurring,
          'groups': routine.groups,
          'conditions': routine.conditions,
          'num_breaks_taken': routine.numBreaksTaken,
          'last_break_at': routine.lastBreakAt?.toUtc().toIso8601String(),
          'paused_until': routine.pausedUntil?.toUtc().toIso8601String(),
          'max_breaks': routine.maxBreaks,
          'max_break_duration': routine.maxBreakDuration,
          'friction': routine.friction.name,
          'friction_len': routine.frictionLen,
          'snoozed_until': routine.snoozedUntil?.toUtc().toIso8601String(),
          'updated_at': routine.updatedAt.toUtc().toIso8601String(),
          'deleted': routine.deleted,
        })
        .eq('id', routine.id);
      }
    }

    db.clearChangesSince(pulledAt);

    final remoteDevices = (await _client
        .from('devices')
        .select('last_pulled_at')
        .eq('user_id', _userId));

    final deviceList = remoteDevices
        .map<String>((d) => d['last_pulled_at'])
        .toList();

    deviceList.sort((a, b) => a.compareTo(b));

    if (deviceList.isNotEmpty) {
      final pulledAt = deviceList[0];

      await _client.from('routines').delete().lt('updated_at', pulledAt).eq('deleted', true);
      await _client.from('groups').delete().lt('updated_at', pulledAt).eq('deleted', true);
      await _client.from('devices').delete().lt('updated_at', pulledAt).eq('deleted', true);
    }

    if (notifyRemote) {
      _notifyPeers();
    }

    return true;
  }
}