import 'dart:async';
import 'setup.dart';
import 'database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  }
  
  factory SyncService() {
    return _instance;
  }

  void _setupRealtimeSync() {
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
          // When we receive a sync message from another client, queue a sync job
          print('event sync');
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

  Future<Changes> fetchRemoteChanges([DateTime? lastPulledAt]) async {
    final userId = _userId;
    if (userId.isEmpty) return (routines: TableChanges(upserts: [], deletes: []), groups: TableChanges(upserts: [], deletes: []), devices: TableChanges(upserts: [], deletes: []));

    final routineQuery = _client.from('routines').select().eq('user_id', userId);
    final groupQuery = _client.from('groups').select().eq('user_id', userId);
    final deviceQuery = _client.from('devices').select().eq('user_id', userId);

    if (lastPulledAt != null) {
      routineQuery.gte('updated_at', lastPulledAt.toUtc().toIso8601String());
      groupQuery.gte('updated_at', lastPulledAt.toUtc().toIso8601String());
      deviceQuery.gte('updated_at', lastPulledAt.toUtc().toIso8601String());
    }

    final results = await Future.wait([
      routineQuery,
      groupQuery,
      deviceQuery,
    ]);

    final routineData = results[0];
    final groupData = results[1];
    final deviceData = results[2];

    return (
      routines: TableChanges(
        upserts: routineData.where((r) => r['deleted'] != true).toList(),
        deletes: routineData.where((r) => r['deleted'] == true).map((r) => r['id'].toString()).toList(),
      ),
      groups: TableChanges(
        upserts: groupData.where((g) => g['deleted'] != true).toList(),
        deletes: groupData.where((g) => g['deleted'] == true).map((g) => g['id'].toString()).toList(),
      ),
      devices: TableChanges(
        upserts: deviceData.where((d) => d['deleted'] != true).toList(),
        deletes: deviceData.where((d) => d['deleted'] == true).map((d) => d['id'].toString()).toList(),
      )
    );
  }

  Future<Changes> fetchLocalChanges([DateTime? lastPulledAt]) async {
    final db = getIt<AppDatabase>();

    // Get changes since lastPulledAt for each table
    final routineChanges = await db.getRoutineChanges(lastPulledAt);
    final groupChanges = await db.getGroupChanges(lastPulledAt);
    final deviceChanges = await db.getDeviceChanges(lastPulledAt);

    return (
      routines: TableChanges(
        upserts: routineChanges.where((r) => !r.deleted).map((r) => r.toJson()).toList(),
        deletes: routineChanges.where((r) => r.deleted).map((r) => r.id).toList(),
      ),
      groups: TableChanges(
        upserts: groupChanges.where((g) => !g.deleted).map((g) => g.toJson()).toList(),
        deletes: groupChanges.where((g) => g.deleted).map((g) => g.id).toList(),
      ),
      devices: TableChanges(
        upserts: deviceChanges.where((d) => !d.deleted).map((d) => d.toJson()).toList(),
        deletes: deviceChanges.where((d) => d.deleted).map((d) => d.id).toList(),
      )
    );
  }

  Future<void> _mergeTableChanges<T>(
    TableChanges changes,
    Future<List<T>> Function(List<String>) getLocalById,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson,
    Future<void> Function(T) upsert,
    Future<void> Function(String) delete,
  ) async {
    final localItems = await getLocalById(changes.upserts.map((e) => e['id'].toString()).toList());
    final localItemMap = { for (final item in localItems) (toJson(item)['id'] as String): item };

    for (var remoteItem in changes.upserts) {
      // Convert snake_case to camelCase for all keys
      remoteItem = Map<String, dynamic>.fromEntries(
        remoteItem.entries.map((e) {
          if (e.key == 'user_id') return null;
          
          // Convert snake_case to camelCase
          final camelKey = e.key.split('_').indexed.map((i) {
            final word = i.$2;
            return i.$1 == 0 ? word : word[0].toUpperCase() + word.substring(1);
          }).join('');
          
          return MapEntry(camelKey, e.value);
        }).whereType<MapEntry<String, dynamic>>()
      );

      final id = remoteItem['id'];

      if (localItemMap.containsKey(id)) {
        final localItem = localItemMap[id]!;
        final localItemData = toJson(localItem);
        final changedColumns = localItemData['changes'] as List<String>? ?? [];

        for (final column in changedColumns) {
          remoteItem[column] = localItemData[column];
        }
      }

      print('saving remote: $remoteItem');

      final item = fromJson(remoteItem);
      await upsert(item);
    }

    for (final remoteId in changes.deletes) {
      await delete(remoteId);
    }
  }

  Future<DateTime> pullChanges() async {
    final db = getIt<AppDatabase>();
    
    final lastPulledAt = await db.getLastPulledAt();
    final pulledAt = DateTime.now().toUtc();
    final changes = await fetchRemoteChanges(lastPulledAt);

    // Handle routines
    await _mergeTableChanges<RoutineEntry>(
      changes.routines,
      db.getRoutinesById,
      (r) => r.toJson(),
      RoutineEntry.fromJson,
      (r) => db.upsertRoutine(r.toCompanion(false)),
      db.deleteRoutine,
    );

    // Handle groups
    await _mergeTableChanges<GroupEntry>(
      changes.groups,
      db.getGroupsById,
      (g) => g.toJson(),
      GroupEntry.fromJson,
      (g) => db.upsertGroup(g.toCompanion(false)),
      db.deleteGroup,
    );

    // Handle devices
    await _mergeTableChanges<DeviceEntry>(
      changes.devices,
      db.getDevicesById,
      (d) => d.toJson(),
      DeviceEntry.fromJson,
      (d) => db.upsertDevice(d.toCompanion(true)),
      db.deleteDevice,
    );

    return pulledAt;
  }

  Future<bool> pushChanges(DateTime pulledAt) async {
    final db = getIt<AppDatabase>();
    final changes = await fetchLocalChanges();
    
    // Check for conflicts in each table
    final routineConflicts = await _checkConflicts('routines', changes.routines, pulledAt);
    final groupConflicts = await _checkConflicts('groups', changes.groups, pulledAt);
    final deviceConflicts = await _checkConflicts('devices', changes.devices, pulledAt);
    
    if (routineConflicts || groupConflicts || deviceConflicts) {
      return false;
    }

    // Push changes for each table
    await _pushTableChanges('routines', changes.routines, pulledAt);
    await _pushTableChanges('groups', changes.groups, pulledAt);
    await _pushTableChanges('devices', changes.devices, pulledAt);

    // Clear local change tracking
    await db.clearChangesSince(pulledAt);

    // Notify other clients about the changes
    await _notifyPeers();

    return true;
  }

  Future<bool> _checkConflicts(String table, TableChanges changes, DateTime pulledAt) async {
    if (changes.upserts.isEmpty && changes.deletes.isEmpty) return false;

    final ids = [
      ...changes.upserts.map((e) => e['id'].toString()),
      ...changes.deletes,
    ];

    if (ids.isEmpty) return false;

    final results = await _client
      .from(table)
      .select('updated_at')
      .inFilter('id', ids)
      .gt('updated_at', pulledAt.toUtc().toIso8601String());

    print('conflicts $pulledAt ($table): $results');

    return results.isNotEmpty;
  }

  Future<void> _pushTableChanges(String table, TableChanges changes, DateTime pulledAt) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    // Handle upserts
    for (final item in changes.upserts) {
      final changes = item['changes'];
      final changedFields = ((changes ?? []) as List<dynamic>).cast<String>();
      if (changes != null && changedFields.isEmpty) continue;

      // Convert all fields to snake_case for Supabase
      final updates = Map.fromEntries(
        item.entries.map((e) {
          if (e.key == 'changes') return null; // Skip changes field
          final snakeKey = e.key.replaceAllMapped(
            RegExp(r'[A-Z]'),
            (match) => '_${match.group(0)?.toLowerCase()}'
          );
          var value = e.value;
          // Convert DateTime values to UTC ISO string
          if (value is DateTime) {
            value = value.toUtc().toIso8601String();
          }
          return MapEntry(snakeKey, value);
        }).whereType<MapEntry<String, dynamic>>()
      );

      // Ensure updated_at is set to pulledAt and include user_id
      updates['updated_at'] = pulledAt.toUtc().toIso8601String();
      updates['last_pulled_at'] = pulledAt.toUtc().toIso8601String();
      updates['user_id'] = userId;

      print('saving local: $updates');
      await _client
        .from(table)
        .upsert(updates)
        .eq('id', item['id'])
        .eq('user_id', userId);
    }

    // Handle deletes
    if (changes.deletes.isNotEmpty) {
      await _client
        .from(table)
        .update({
          'deleted': true,
          'updated_at': pulledAt.toUtc().toIso8601String(),
        })
        .inFilter('id', changes.deletes);
    }
  }

  Future<void> deleteStaleRemoteEntries(DateTime pulledAt) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    // Get all devices and their last_pulled_at timestamps
    final devices = await _client
      .from('devices')
      .select('last_pulled_at')
      .eq('deleted', false)
      .eq('user_id', userId);

    if (devices.isEmpty) return; // No devices to check

    // Find the oldest last_pulled_at timestamp
    final oldestPull = devices
      .map((d) => DateTime.parse(d['last_pulled_at'] as String).toUtc())
      .reduce((a, b) => a.isBefore(b) ? a : b);

    // Delete entries marked as deleted that are older than the oldest last_pulled_at
    // This ensures all devices have synced these deletions
    final tables = ['routines', 'groups', 'devices'];
    
    await Future.wait(
      tables.map((table) => _client
        .from(table)
        .delete()
        .eq('deleted', true)
        .eq('user_id', userId)
        .lte('updated_at', oldestPull.toIso8601String())
      )
    );
  }

  // order matters: devices, groups, routines
  Future<void> _sync(bool notifyRemote) async {
    if (_userId.isEmpty) return;
    
    print('Syncing...');

    // Ensure we're subscribed to the sync channel
    _setupRealtimeSync();

    // pull changes
    // TODO: skip this if not connected/not subscribed
    final pulledAt = await pullChanges();

    // push changes
    final success = await pushChanges(pulledAt);

    if (success) {
      await deleteStaleRemoteEntries(pulledAt);
      print('Sync successful');
    } else {
      // TODO: try again up to x times
      print('Sync failed');
    }
  }
}