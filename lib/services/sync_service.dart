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
  bool _lastKnownSyncStatus = false;
  final Lock _syncLock = Lock();
  
  // Stream controller for sync failure events
  final StreamController<void> _syncFailureController = StreamController<void>.broadcast();

  String get userId => Supabase.instance.client.auth.currentUser?.id ?? '';
  
  SyncService._internal() : 
    _client = Supabase.instance.client {
    setupRealtimeSync();
  }
  
  factory SyncService() {
    return _instance;
  }
  
  // Stream that UI components can listen to for sync failure events
  Stream<void> get onSyncFailure => _syncFailureController.stream;

  SyncService.simple() : 
    _client = Supabase.instance.client;

  void setupRealtimeSync() {
    if (userId.isEmpty) return;

    _syncChannel?.unsubscribe();

    try {
      _syncChannel = _client.channel('sync-$userId');

      _syncChannel!
        .onBroadcast( 
          event: 'sync', 
          callback: (payload, [_]) {
            logger.i('received remote sync request from ${payload['source']}');
            queueSync();
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

    logger.i("notfying peers");

    await _sendRealtimeMessage('sync');

    try {
      _client.functions.invoke('push', body: {'content': 'sample message', 'source_id': currDevice.id});
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
  }

  Future<bool> queueSync({bool full = false}) async {
    if (Util.isDesktop()) {
      sync(full: full);
      return true;
    } else  {
      // Clear existing keys in shared_preferences prefixed with sync_job_status_
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final syncStatusKeys = allKeys.where((key) => key.startsWith('sync_job_status_'));
      
      for (final key in syncStatusKeys) {
        await prefs.remove(key);
      }
      
      // Generate a new UUID for this sync job
      final id = Uuid().v4();
      
      // Store the latest sync job ID
      _latestSyncJobId = id;
      _lastKnownSyncStatus = false;
      
      // Write false to shared preferences under "sync_job_status_${id}"
      await prefs.setBool('sync_job_status_$id', false);
      
      // Start polling for status changes
      _startSyncStatusPolling();
      
      await Workmanager().registerOneOffTask("sync", "sync-task", inputData: {'full': full, 'id': id});

      return true;
    }
  }

  Future<bool> sync({bool full = false, String? id}) async {
    logger.i("syncing...");

    SyncResult? result;
    await _syncLock.synchronized(() async {
      result = await _sync(full: full);
    });
  
    final success = result != null;
    logger.i("finished syncing - success = $success");

    if (id != null) {
      final key = 'sync_job_status_$id';
      logger.i("setting sync key $key to true");
      await SharedPreferencesAsync().setBool(key, true);
    } else {
      logger.i("no id for this sync job");
    }

    if (!success) {
      _syncFailureController.add(null);
    }

    return success;
  }

  // Start polling for sync job status changes
  void _startSyncStatusPolling() {
    // Stop any existing polling
    _stopSyncStatusPolling();
    
    // Initialize the last known status
    _lastKnownSyncStatus = false;
    
    // Start a new polling timer
    _syncStatusPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkSyncStatusChanges();
    });
    
    logger.i("Started sync status polling");
  }
  
  // Stop polling for sync job status changes
  void _stopSyncStatusPolling() {
    if (_syncStatusPollingTimer != null) {
      _syncStatusPollingTimer!.cancel();
      _syncStatusPollingTimer = null;
      logger.i("Stopped sync status polling");
    }
  }
  
  // Check for changes in the latest sync job status
  Future<void> _checkSyncStatusChanges() async {
    try {
      if (_latestSyncJobId == null) {
        // No sync job to check
        logger.i("no sync job to check");

        _stopSyncStatusPolling();
        return;
      }
      
      final prefs = SharedPreferencesAsync();
      final key = 'sync_job_status_$_latestSyncJobId';

      logger.i("checking sync status for key $key = ${await prefs.getBool(key)}");
      
      final currentStatus = await prefs.getBool(key) ?? false;

      // If status changed from false to true
      if (!_lastKnownSyncStatus && currentStatus) {
        logger.i("Latest sync job $_latestSyncJobId completed");
        
        // Notify changes
        logger.i("Sync job status changed, notifying changes");
        final db = getIt<AppDatabase>();
        await db.forceNotifyChanges();
        
        // Stop polling since the job is complete
        _stopSyncStatusPolling();
      }
      
      // Update the last known status
      _lastKnownSyncStatus = currentStatus;
      
    } catch (e, st) {
      logger.e("Error checking sync status changes: $e");
      Util.report('error checking sync status changes', e, st);
    }
  }
  
  Future<SyncResult?> _sync({bool full = false}) async {
    try {
      if (userId.isEmpty) {
        logger.i("can't sync - user is not signed in");
        return null;
      }

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
            .eq('id', userId)
            .maybeSingle() ?? 
          await _client.from('users').insert({
            'id': userId,
            'emergencies': [],
          }).maybeSingle() as Map<String, dynamic>;

        // Parse remote and local events
        final remoteEvents = <EmergencyEvent>[];
        if (userData['emergencies'] != null) {
          final List<dynamic> eventsList = userData['emergencies'] as List<dynamic>;
          for (final event in eventsList) {
            remoteEvents.add(EmergencyEvent.fromJson(Map<String, dynamic>.from(event)));
          }
        }
        final localEvents = StrictModeService().emergencyEvents;

         // Create maps for local and remote events (id -> event)
        final Map<String, EmergencyEvent> localEventMap = {
          for (final event in localEvents) event.id: event
        };
        final Map<String, EmergencyEvent> remoteEventMap = {
          for (final event in remoteEvents) event.id: event
        };
        
        // Merge events by id, preferring the one with the latest endedAt
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
        
        // Filter out events older than one week
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        mergedEvents.removeWhere((event) => 
          event.endedAt != null && event.endedAt!.isBefore(oneWeekAgo));
        
        // Sort events by startedAt to find the latest
        mergedEvents.sort((a, b) => a.startedAt.compareTo(b.startedAt));
        
        if (mergedEvents.isNotEmpty) {
          final latestEvent = mergedEvents.last;
          
          for (int i = 0; i < mergedEvents.length - 1; i++) {
            final event = mergedEvents[i];
            event.endedAt = event.endedAt ?? latestEvent.startedAt;
          }
        }
        
        logger.i("localEvents: ${localEvents.map((e) => e.toJson())}");
        logger.i("remoteEvents: ${remoteEvents.map((e) => e.toJson())}");
        logger.i("mergedEvents: ${mergedEvents.map((e) => e.toJson())}");
        
        madeRemoteChange = madeRemoteChange || (mergedEvents.length != remoteEvents.length);
        for (final event in mergedEvents) {
          madeRemoteChange = madeRemoteChange 
          || event.startedAt != remoteEventMap[event.id]?.startedAt
          || event.endedAt != remoteEventMap[event.id]?.endedAt;
        }
        
        await StrictModeService().updateEmergencyEvents(mergedEvents);

        await _client.from('users').update({
          'emergencies': mergedEvents.map((e) => e.toJson()).toList(),
        }).eq('id', userId);
      }
      
      final result = await db.transaction(() async {
        // pull devices
        {
          final remoteDevices = await _client.from('devices').select()
              .eq('user_id', userId)
              .or('updated_at.gt.${lastPulledAt.toUtc().toIso8601String()},id.eq.${currDevice.id}');
          final localDevices = await db.getDevicesById(remoteDevices.map((device) => device['id'] as String).toList());
          final localDeviceMap = {for (final device in localDevices) device.id: device};
          logger.i("remote devices: $remoteDevices");
          
          final deviceSyncedBefore = remoteDevices.any((device) => device['id'] == currDevice.id);

          logger.i("device synced before: $deviceSyncedBefore");

          // if the current device doesn't exist remotely, we need to do a full sync
          full = full || !deviceSyncedBefore;

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

            final DateTime updatedAt = pulledAt.toIso8601String().compareTo(device['updated_at']) > 0 ? pulledAt : DateTime.parse(device['updated_at']);
            final DateTime deviceLastSynced = localDevice?.lastPulledAt != null && localDevice!.lastPulledAt!.toIso8601String().compareTo(device['last_pulled_at']) > 0 ? localDevice.lastPulledAt! : DateTime.parse(device['last_pulled_at']);

            // Check if this is the current device or an active device that was mistakenly deleted
            final isCurrentDevice = localDevice?.curr ?? false;
            final isActiveDevice = device['id'] == currDevice.id;
            
            if (device['deleted'] as bool && (isCurrentDevice || isActiveDevice)) {
              // This is an active device that was mistakenly marked as deleted
              // We need to restore it and any associated groups
              accidentalDeletion = true;
              
              await db.upsertDevice(DevicesCompanion(
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
        }

        // pull groups
        {
          final remoteGroups = await _client.from('groups').select().eq('user_id', userId).gt('updated_at', lastPulledAt.toUtc().toIso8601String());
          final localGroups = await db.getGroupsById(remoteGroups.map((group) => group['id'] as String).toList());
          final localGroupMap = {for (final group in localGroups) group.id: group};
          logger.i("remote groups: $remoteGroups");
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

            final DateTime updatedAt = pulledAt.toIso8601String().compareTo(group['updated_at']) > 0 ? pulledAt : DateTime.parse(group['updated_at']);

            if (group['deleted'] as bool) {
              if (group['device'] == currDevice.id && accidentalDeletion) {
                await db.upsertGroup(GroupsCompanion(
                  id: Value(group['id']),
                  name: Value(overwriteMap['name'] ?? group['name'] as String?),
                  device: Value(overwriteMap['device'] ?? group['device'] as String?),
                  allow: Value(overwriteMap['allow'] ?? group['allow'] as bool?),
                  updatedAt: Value(DateTime.now()),
                  deleted: Value(false),
                  changes: Value(['deleted', ...overwriteMap['changes'] ?? const []])
                ));
              } else {
                await db.deleteGroup(group['id']);
              }
            } else {
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
        }
      
        // pull routines
        {
          final remoteRoutines = await _client.from('routines').select().eq('user_id', userId).gt('updated_at', lastPulledAt.toUtc().toIso8601String());
          final localRoutines = await db.getRoutinesById(remoteRoutines.map((routine) => routine['id'] as String).toList());
          final localRoutineMap = {for (final routine in localRoutines) routine.id: routine};
          
          logger.i("remote routines: $remoteRoutines");
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

            final DateTime updatedAt = pulledAt.toIso8601String().compareTo(routine['updated_at']) > 0 ? pulledAt : DateTime.parse(routine['updated_at']);
            
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

        await db.updateDevice(DevicesCompanion(
          id: Value(currDevice.id),
          lastPulledAt: Value(pulledAt),
          updatedAt: Value(pulledAt),
        ));
      });

      print("sync result: $result");

      // push devices
      final localDevices = await db.getDeviceChanges(full ? null : lastPulledAt);

      logger.i("local devices: $localDevices");
      final remoteDevices = await _client
        .from('devices')
        .select()
        .eq('user_id', userId)
        .inFilter('id', localDevices.map((device) => device.id).toList());

      final remoteDeviceMap = {for (final device in remoteDevices) device['id']: device};
      for (final device in localDevices) {
        final remoteDevice = remoteDeviceMap[device.id];
        if (remoteDevice != null && remoteDevice['updated_at'].compareTo(pulledAt.toUtc().toIso8601String()) > 0) {
          logger.i("device conflict detected - cancelling sync");
          return null;
        }
      }

      // push groups    
      final localGroups = await db.getGroupChanges(full ? null : lastPulledAt);
      logger.i("local groups: $localGroups");
      final remoteGroups = await _client
        .from('groups')
        .select()
        .eq('user_id', userId)
        .inFilter('id', localGroups.map((group) => group.id).toList());

      final remoteGroupMap = {for (final group in remoteGroups) group['id']: group};
      
      for (final group in localGroups) {
        final remoteGroup = remoteGroupMap[group.id];
        if (remoteGroup != null && remoteGroup['updated_at'].compareTo(pulledAt.toUtc().toIso8601String()) > 0) {
          logger.i("group conflict detected - cancelling sync");
          return null;
        }
      }

      // push routines
      final localRoutines = await db.getRoutineChanges(full ? null : lastPulledAt);
      logger.i("local routines: $localRoutines");
      final remoteRoutines = await _client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .inFilter('id', localRoutines.map((routine) => routine.id).toList());
      final remoteRoutineMap = {for (final routine in remoteRoutines) routine['id']: routine};
      
      for (final routine in localRoutines) {
        final remoteRoutine = remoteRoutineMap[routine.id];
        if (remoteRoutine != null && remoteRoutine['updated_at'].compareTo(pulledAt.toUtc().toIso8601String()) > 0) {
          logger.i("routine conflict detected - cancelling sync");
          return null;
        }
      }

      // persist devices
      bool updatedCurrDevice = false;
      for (final device in localDevices) {
        madeRemoteChange = true;

        updatedCurrDevice = updatedCurrDevice || device.id == currDevice.id;          

        final Map<String, dynamic> data = {
          'id': device.id, 
          'user_id': userId,
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
        madeRemoteChange = true;
        await _client
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
        .eq('id', group.id);
      }

      // persist routines
      for (final routine in localRoutines) {
        madeRemoteChange = true;
        await _client
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
        .eq('id', routine.id);
      }

      // clean up soft deleted entries
      await db.clearChangesSince(pulledAt);
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

          await _client.from('routines').delete().lt('updated_at', pulledAt).eq('deleted', true);
          await _client.from('groups').delete().lt('updated_at', pulledAt).eq('deleted', true);
          await _client.from('devices').delete().lt('updated_at', pulledAt).eq('deleted', true);
        }
      }
    
      // notify other clients
      if (madeRemoteChange) {
        _notifyPeers();
      }

      

      return SyncResult();
    } catch (e, st) {
      Util.report('error syncing', e, st);
      return null;
    }
  }
}