import 'package:drift/drift.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../database/database.dart';
import '../setup.dart';
import '../services/sync_service.dart';
import 'syncable.dart';

enum DeviceType {
  windows,
  linux,
  macos,
  ios,
  ipad,
  android
}

class Device implements Syncable {
  late String name;
  final String _id;
  late final DeviceType _type;
  late final bool _curr;
  late DateTime? _lastPulledAt;
  DeviceEntry? _entry;

  static Stream<List<Device>> watchAll() {
    return getIt<AppDatabase>()
      .watchDevices()
      .map((entries) => entries.map((e) => Device.fromEntry(e)).toList());
  }

  static Future<Device> getCurrent() async {
    final deviceEntry = await getIt<AppDatabase>().getThisDevice();

    if (deviceEntry != null) {
      return Device.fromEntry(deviceEntry);
    } else {
      final device = await Device.create(currDevice: true);
      await device.save();
      return device;
    }
  }

  Device._({required String id, required bool currDevice}) : _id = id, _curr = currDevice {
    _lastPulledAt = null;
    _initDeviceType();
  }
  
  static Future<Device> create({bool currDevice = false}) async {
    final id = await _generateDeviceHash();
    return Device._(id: id, currDevice: currDevice);
  }

  void _initDeviceType() async {
    name = "";
    if (Platform.isMacOS) {
      name = "Macbook";
      _type = DeviceType.macos;
    } else if (Platform.isLinux) {
      name = "Linux";
      _type = DeviceType.linux;
    } else if (Platform.isWindows) {
      name = "Windows";
      _type = DeviceType.windows;
    } else if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      if (iosInfo.model.toLowerCase().contains('ipad')) {
        name = "iPad";
        _type = DeviceType.ipad;
      } else {
        name = "iPhone";
        _type = DeviceType.ios;
      }
    } else if (Platform.isAndroid) {
      name = "Android";
      _type = DeviceType.android;
    } else {
      throw Exception('Unsupported platform');
    }
  }

  @override
  Future<void> delete() async { 
    await getIt<AppDatabase>().tempDeleteDevice(id);
    await SyncService().queueSync();
  }
  
  @override
  Future<void> save() async {
    final changes = this.changes;

    if (_entry == null) {
      changes.add('new');
    }
    
    await getIt<AppDatabase>().upsertDevice(DevicesCompanion(
      id: Value(_id),
      name: Value(name),
      type: Value(_type.name),
      curr: Value(_curr),
      updatedAt: Value(DateTime.now()),
      deleted: Value(false),
      changes: Value(changes),
    ));

    await SyncService().queueSync();
  }

  Device.fromEntry(DeviceEntry entry)
      : _id = entry.id,
        name = entry.name,
        _type = DeviceType.values.byName(entry.type),
        _curr = entry.curr,
        _lastPulledAt = entry.lastPulledAt,
        _entry = entry;
        
  static Future<String> _generateDeviceHash() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isMacOS) {
      final macData = await deviceInfo.macOsInfo;
      deviceId = '${macData.systemGUID};';
    } else if (Platform.isLinux) {
      final linuxData = await deviceInfo.linuxInfo;
      deviceId = '${linuxData.id};';
    } else if (Platform.isWindows) {
      final windowsData = await deviceInfo.windowsInfo;
      deviceId = '${windowsData.deviceId};';
    } else if (Platform.isIOS) {
      final iosData = await deviceInfo.iosInfo;
      deviceId = '${iosData.identifierForVendor};';
    } else if (Platform.isAndroid) {
      final androidData = await deviceInfo.androidInfo;
      deviceId = '${androidData.id};';
    }
    
    final bytes = utf8.encode(deviceId);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  @override
  List<String> get changes {
    final List<String> changes = [];

    if (name != _entry?.name) {
      changes.add('name');
    }

    return changes;
  }

  @override
  String get id => _id;
  DeviceType get type => _type;
  bool get curr => _curr;
  DateTime? get lastPulledAt => _lastPulledAt;
  
  @override
  bool get saved => _entry != null;
  
  @override
  bool get modified => _entry == null || changes.isNotEmpty;
  
  String get formattedType {
    switch (_type) {
      case DeviceType.windows:
        return 'Windows';
      case DeviceType.linux:
        return 'Linux';
      case DeviceType.macos:
        return 'macOS';
      case DeviceType.ios:
        return 'iOS';
      case DeviceType.ipad:
        return 'iPad';
      case DeviceType.android:
        return 'Android';
    }
  }
  
  String get lastSyncStatus {
    if (_lastPulledAt == null) {
      return 'Never synced';
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastPulledAt!);
    
    if (difference.inSeconds < 60) {
      return 'Synced just now';
    } else if (difference.inMinutes < 60) {
      return 'Synced ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return 'Synced ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      return 'Synced ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return 'Synced on ${_lastPulledAt!.month}/${_lastPulledAt!.day}/${_lastPulledAt!.year}';
    }
  }
}