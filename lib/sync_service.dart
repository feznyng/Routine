import 'dart:async';
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
    _setupRealtimeSync();
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

  // order matters: devices, groups, routines
  Future<bool> _sync(bool notifyRemote) async {
    if (_userId.isEmpty) return true;
    
    final db = getIt<AppDatabase>();
    final currDevice = (await db.getThisDevice())!;
    final lastPulledAt = currDevice.lastPulledAt;
    final pulledAt = DateTime.now();

    {
      final remoteDevices = await _client.from('devices').select().eq('user_id', _userId).gt('updated_at', pulledAt);
      print('remote device changes: $remoteDevices');
     
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

        final updatedAt = localDevice != null && localDevice.updatedAt.toIso8601String().compareTo(device['updated_at']) > 0 ? localDevice.updatedAt : device['updated_at'];

        if (device['deleted'] as bool) {
          db.deleteDevice(device['id']);
        } else {
           db.upsertDevice(DevicesCompanion(
            id: Value(device['id']),
            name: Value(overwriteMap['name'] ?? device['name']),
            type: Value(device['type']),
            curr: Value(false),
            updatedAt: Value(updatedAt),
            deleted: Value(device['deleted']),
          ));
        }
      }
    }

    {
      final localDevices = await db.getDeviceChanges(lastPulledAt);
      print('local device changes: $localDevices');
      final remoteDevices = await _client
        .from('devices')
        .select()
        .eq('user_id', _userId)
        .inFilter('id', localDevices.map((device) => device.id).toList());
      final remoteDeviceMap = {for (final device in remoteDevices) device['id']: device};
      for (final device in localDevices) {
        final remoteDevice = remoteDeviceMap[device.id];
        if (remoteDevice != null && remoteDevice['updated_at'].compareTo(pulledAt.toIso8601String()) > 0) {
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
          'updated_at': device.updatedAt.toIso8601String(),
          'deleted': device.deleted,
        })
        .eq('id', device.id);
      }
    }

    db.updateDevice(DevicesCompanion(
      id: Value(currDevice.id),
      lastPulledAt: Value(pulledAt),
    ));

    if (notifyRemote) {
      _notifyPeers();
    }

    return true;
  }
}