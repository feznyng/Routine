import 'dart:async';
import 'package:Routine/models/emergency_event.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:Routine/models/condition.dart';
import 'package:Routine/models/device.dart';
import '../setup.dart';
import '../database/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import 'strict_mode_service.dart';

class SyncJob {
  bool remote;
  bool full;

  SyncJob({required this.remote, this.full = false});
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
  final AppDatabase db;
  final SupabaseClient _client;
  late final String _userId;
  
  SyncService._internal() : 
    db = getIt<AppDatabase>(),
    _client = Supabase.instance.client {
    _userId = Supabase.instance.client.auth.currentUser?.id ?? '';
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

    try {
      // Subscribe to sync channel for this user
      _syncChannel = _client.channel('sync-$userId');

      _syncChannel!
        .onBroadcast( 
          event: 'sync', 
          callback: (payload, [_]) {
            print('received remote sync request from ${payload['source']}');
            addJob(SyncJob(remote: true));
          }
        )
        .subscribe();
    } catch (e) {
      print('Error setting up realtime sync: $e');
      // We'll try again later when the app resumes or when auth state changes
    }
  }

  Future<void> _notifyPeers() async {
    final currDevice = await Device.getCurrent();

    try {
      final channel = _syncChannel;
      if (channel != null) {
        await channel.sendBroadcastMessage(
          event: 'sync',
          payload: { 'timestamp': DateTime.now().toIso8601String(), 'source': currDevice.id },
        );
      }
    } catch (e) {
      print('Error notifying peers: $e');
      setupRealtimeSync();
    }

    try {
      _client.functions.invoke('push', body: {'content': 'sample message', 'source_id': currDevice.id});
    } catch (e) {
      print('Error sending fcm message: $e');
    }
  }
  
  final _jobController = StreamController<SyncJob>();
  Timer? _batchTimer;
  final List<SyncJob> _pendingJobs = [];
  bool _isProcessing = false;
  
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
    
    _batchTimer = Timer(Duration(seconds: 1), () {
      if (!_isProcessing) {
        _processJobs();
      }
    });
  }
  
  Future<void> _processJobs() async {
    if (_isProcessing || _pendingJobs.isEmpty) return;
    
    _isProcessing = true;
    
    try {
      // Add a short delay to allow more jobs to accumulate
      await Future.delayed(Duration(milliseconds: 100));
      
      // Check if more jobs came in during the delay
      if (!_isProcessing) return;
      
      final batchJobs = List<SyncJob>.from(_pendingJobs);
      _pendingJobs.clear();
      
      if (batchJobs.isNotEmpty) {
        final shouldNotifyRemote = batchJobs.any((job) => !job.remote);
        final isFullSync = batchJobs.any((job) => job.full);
        await sync(shouldNotifyRemote, full: isFullSync);
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

  Future<bool> sync(bool notifyRemote, {bool full = false}) async {
    try {
      if (_userId.isEmpty) return true;

      // Check for internet connectivity
      final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
      if (!connectivityResult.contains(ConnectivityResult.wifi) && 
            !connectivityResult.contains(ConnectivityResult.ethernet) && 
            !connectivityResult.contains(ConnectivityResult.vpn) && 
            !connectivityResult.contains(ConnectivityResult.mobile) 
            ) {
        print('No internet connection, skipping sync');
        return true;
      }

      print("syncing...");
      
      final db = getIt<AppDatabase>();
      final currDevice = (await db.getThisDevice())!;

      final lastPulledAt = full ? DateTime.fromMicrosecondsSinceEpoch(0) : (currDevice.lastPulledAt ?? DateTime.fromMicrosecondsSinceEpoch(0));
      final pulledAt = DateTime.now();

      bool madeRemoteChange = false;
      bool accidentalDeletion = false;

      // sync emergencies first due to criticality
      {
        final userData = await _client.from('users')
            .select('emergencies')
            .eq('id', _userId)
            .maybeSingle() ?? 
          await _client.from('users').insert({
            'id': _userId,
            'emergencies': [],
          }).select() as Map<String, dynamic>;

        // Parse remote and local events
        final remoteEvents = <EmergencyEvent>[];
        if (userData['emergencies'] != null) {
          final List<dynamic> eventsList = userData['emergencies'] as List<dynamic>;
          for (final event in eventsList) {
            remoteEvents.add(EmergencyEvent.fromJson(Map<String, dynamic>.from(event)));
          }
        }
        final localEvents = StrictModeService().emergencyEvents;

        // First clean up old events (older than a week)
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        final recentEvents = [...remoteEvents, ...localEvents]
          .where((e) => !e.startedAt.isBefore(oneWeekAgo))
          .toList();

        // Merge events, ensuring only one active emergency
        final mergedEvents = <EmergencyEvent>[];

        // Find the latest active emergency if any
        final activeEvents = recentEvents.where((e) => e.endedAt == null).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

        EmergencyEvent? latestActive;
        if (activeEvents.isNotEmpty) {
          latestActive = activeEvents.first;
          // End all other active events at the time the latest one started
          for (final event in activeEvents.skip(1)) {
            event.endedAt = latestActive.startedAt;
          }
        }

        // Now process all events, keeping track of seen IDs
        final seenIds = <String>{};
        final processedEvents = <EmergencyEvent>[];

        // Add the latest active event first if it exists
        if (latestActive != null) {
          processedEvents.add(latestActive);
          seenIds.add(latestActive.id);
        }

        // Add all other events, preferring ended versions
        final eventsByIds = <String, List<EmergencyEvent>>{};
        for (final event in recentEvents.where((e) => !seenIds.contains(e.id))) {
          eventsByIds.putIfAbsent(event.id, () => []).add(event);
        }

        for (final events in eventsByIds.values) {
          final endedEvent = events.firstWhere(
            (e) => e.endedAt != null,
            orElse: () => events.first
          );
          processedEvents.add(endedEvent);
        }

        mergedEvents.addAll(processedEvents);

        // Update local state
        await StrictModeService().updateEmergencyEvents(mergedEvents);

        // Update remote state
        await _client.from('users').update({
          'emergencies': mergedEvents.map((e) => e.toJson()).toList(),
        }).eq('id', _userId);
      }
      
      // pull devices
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
              if (change == 'new') {
                continue;
              }
              overwriteMap[change] = localDeviceData[change];
            }
          }

          final DateTime updatedAt = localDevice != null && localDevice.updatedAt.toIso8601String().compareTo(device['updated_at']) > 0 ? localDevice.updatedAt : DateTime.parse(device['updated_at']);
          final DateTime deviceLastSynced = localDevice?.lastPulledAt != null && localDevice!.lastPulledAt!.toIso8601String().compareTo(device['last_pulled_at']) > 0 ? localDevice.lastPulledAt! : DateTime.parse(device['last_pulled_at']);

          // Check if this is the current device or an active device that was mistakenly deleted
          final isCurrentDevice = localDevice?.curr ?? false;
          final isActiveDevice = device['id'] == currDevice.id;
          
          if (device['deleted'] as bool && (isCurrentDevice || isActiveDevice)) {
            // This is an active device that was mistakenly marked as deleted
            // We need to restore it and any associated groups
            accidentalDeletion = true;
            
            db.upsertDevice(DevicesCompanion(
              id: Value(device['id']),
              name: Value(overwriteMap['name'] ?? device['name']),
              type: Value(overwriteMap['type'] ?? device['type']),
              curr: Value(isCurrentDevice),
              updatedAt: Value(updatedAt),
              lastPulledAt: Value(deviceLastSynced),
              deleted: Value(false), // Explicitly set to false to restore
              changes: Value(['deleted', ...overwriteMap['changes'] ?? const []]), // Mark 'deleted' as changed
            ));
            
          } else if (device['deleted'] as bool) {
            db.deleteDevice(device['id']);
          } else {
              db.upsertDevice(DevicesCompanion(
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
      }

      // pull groups
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
              if (change == 'new') {
                continue;
              }
              overwriteMap[change] = localGroupData[change];
            }
          }

          final DateTime updatedAt = localGroup != null && localGroup.updatedAt.toIso8601String().compareTo(group['updated_at']) > 0 ? localGroup.updatedAt : DateTime.parse(group['updated_at']);

          if (group['deleted'] as bool) {
            if (group['device'] == currDevice.id && accidentalDeletion) {
              db.upsertGroup(GroupsCompanion(
                id: Value(group['id']),
                name: Value(overwriteMap['name'] ?? group['name'] as String?),
                device: Value(overwriteMap['device'] ?? group['device'] as String?),
                allow: Value(overwriteMap['allow'] ?? group['allow'] as bool?),
                updatedAt: Value(DateTime.now()),
                deleted: Value(false),
                changes: Value(['deleted', ...overwriteMap['changes'] ?? const []])
              ));
            } else {
              db.deleteGroup(group['id']);
            }

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
    
      // pull routines
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
              if (change == 'new') {
                continue;
              }
              overwriteMap[change] = localRoutineData[change];
            }
          }

          final DateTime updatedAt = localRoutine != null && localRoutine.updatedAt.toIso8601String().compareTo(routine['updated_at']) > 0 ? localRoutine.updatedAt : DateTime.parse(routine['updated_at']);
          
          final List<Condition> conditions = routine['conditions'] != null ? 
            (routine['conditions'] as List<dynamic>).map<Condition>((map) => Condition.fromJson(map)).toList() : [];

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

      // push devices
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
          print("device conflict detected - cancelling sync");
          return false;
        }
      }

      // push groups    
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
          print("group conflict detected - cancelling sync");
          return false;
        }
      }

      // push routines
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
          print("routine conflict detected - cancelling sync");
          return false;
        }
      }

      // persist devices
      bool updatedCurrDevice = false;
      for (final device in localDevices) {
        madeRemoteChange = true;
        print("syncing device ${device.changes}");

        updatedCurrDevice = updatedCurrDevice || device.id == currDevice.id;          

        final Map<String, dynamic> data = {
          'id': device.id, 
          'user_id': _userId,
          'name': device.name,
          'type': device.type,
          'updated_at': device.updatedAt.toUtc().toIso8601String(),
          'last_pulled_at': pulledAt.toUtc().toIso8601String(),
          'deleted': device.deleted,
        };

        await _client
        .from('devices')
        .upsert(data)
        .eq('id', device.id);
      }
      
      if (!updatedCurrDevice) {
        await _client
        .from('devices')
        .update({
          'last_pulled_at': pulledAt.toUtc().toIso8601String(),
        })
        .eq('id', currDevice.id);
      }

      // persist groups
      for (final group in localGroups) {
        print("syncing group ${group.changes}");
        madeRemoteChange = true;
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

      // persist routines
      for (final routine in localRoutines) {       
        print("syncing routine ${routine.changes}");

        madeRemoteChange = true;
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
          'updated_at': routine.updatedAt.toUtc().toIso8601String(),
          'deleted': routine.deleted,
        })
        .eq('id', routine.id);
      }

      // clean up soft deleted entries
      db.clearChangesSince(pulledAt);
      {
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
      }
    
      // notify other clients
      if (madeRemoteChange) {
        _notifyPeers();
      }

      return true;
    } catch (e) {
      print('Error during sync: $e');
      return false;
    }
  }
}