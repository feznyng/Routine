import 'dart:async';
import 'device.dart';
import 'setup.dart';
import 'database.dart';
import 'package:drift/drift.dart';
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
  
  SyncService._internal() {
    _startConsumer();
  }
  
  factory SyncService() {
    return _instance;
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
        await sync(batchJobs.any((job) => !job.remote));
      }
    } finally {
      _isProcessing = false;
      
      if (_pendingJobs.isNotEmpty) {
        _scheduleBatchProcessing();
      }
    }
  }
  
  void dispose() {
    _batchTimer?.cancel();
    _jobController.close();
  }

  Future<Changes> fetchRemoteChanges([DateTime? lastPulledAt]) async {
    // TODO: implement pullChanges using supabase
    return (
      routines: TableChanges(upserts: [], deletes: []),
      groups: TableChanges(upserts: [], deletes: []),
      devices: TableChanges(upserts: [], deletes: [])
    );
  }

  Future<Changes> fetchLocalChanges([DateTime? lastPulledAt]) async {
    // TODO: implement pullChanges using drift
    return (
      routines: TableChanges(upserts: [], deletes: []),
      groups: TableChanges(upserts: [], deletes: []),
      devices: TableChanges(upserts: [], deletes: [])
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

    for (final remoteItem in changes.upserts) {
      final id = remoteItem['id'];

      if (localItemMap.containsKey(id)) {
        final localItem = localItemMap[id]!;
        final localItemData = toJson(localItem);
        final changedColumns = localItemData['changes'] as List<String>? ?? [];

        for (final column in changedColumns) {
          remoteItem[column] = localItemData[column];
        }
      }

      final item = fromJson(remoteItem);
      await upsert(item);
    }

    for (final remoteId in changes.deletes) {
      await delete(remoteId);
    }
  }

  Future<void> pullChanges() async {
    final db = getIt<AppDatabase>();
    
    final lastPulledAt = await db.getLastPulledAt();
    final pulledAt = DateTime.now();
    final changes = await fetchRemoteChanges(lastPulledAt);

    // Handle routines
    await _mergeTableChanges<RoutineEntry>(
      changes.routines,
      db.getRoutinesById,
      (r) => r.toJson(),
      RoutineEntry.fromJson,
      (r) => db.upsertRoutine(r.toCompanion(false).copyWith(updatedAt: Value.absent())),
      db.deleteRoutine,
    );

    // Handle groups
    await _mergeTableChanges<GroupEntry>(
      changes.groups,
      db.getGroupsById,
      (g) => g.toJson(),
      GroupEntry.fromJson,
      (g) => db.upsertGroup(g.toCompanion(false).copyWith(updatedAt: Value.absent())),
      db.deleteGroup,
    );

    // Handle devices
    await _mergeTableChanges<DeviceEntry>(
      changes.devices,
      db.getDevicesById,
      (d) => d.toJson(),
      DeviceEntry.fromJson,
      (d) => db.upsertDevice(d.toCompanion(false).copyWith(updatedAt: Value.absent())),
      db.deleteDevice,
    );

    getIt<Device>().setLastPulledAt(pulledAt);
  }

  Future<void> pushChanges() async {
    final db = getIt<AppDatabase>();
    
    final now = DateTime.now();
    final changes = await fetchLocalChanges();

    // TODO: implement pushChanges using supabase

    await db.clearChangesSince(now);
  }

  // order matters: devices, groups, routines
  Future<void> sync(bool notifyRemote) async {

    // pull changes
    // TODO: skip this if not connected/not subscribed
    await pullChanges();

    // push changes
    await pushChanges();

    // TODO: actually delete remote stale flagged entries using min([...devices.lastPulledAt])
  }
}