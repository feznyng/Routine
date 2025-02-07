import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'database.dart';
import 'setup.dart';
import 'sync_service.dart';

enum DeviceType {
  windows,
  linux,
  macos,
  ios,
  android
}

class Device {
  final String _id;
  late final DeviceType _type;
  late final bool _curr;
  late final DateTime? _lastPulledAt;

  static Future<Device> getCurrent() async {
    final deviceEntry = await getIt<AppDatabase>().getThisDevice();

    if (deviceEntry != null) {
      return Device.fromEntry(deviceEntry);
    } else {
      final device =  Device(currDevice: true);
      await device.save();
      return device;
    }
  }

  Device({bool currDevice = false}) : _id = const Uuid().v4() {
    if (Platform.isMacOS) {
      _type = DeviceType.macos;
    } else if (Platform.isLinux) {
      _type = DeviceType.linux;
    } else if (Platform.isWindows) {
      _type = DeviceType.windows;
    } else if (Platform.isIOS) {
      _type = DeviceType.ios;
    } else if (Platform.isAndroid) {
      _type = DeviceType.android;
    } else {
      throw Exception('Unsupported platform');
    }

    _curr = currDevice;
  }
  
  Future<void> save() async {
    await getIt<AppDatabase>().upsertDevice(DevicesCompanion(
      id: Value(_id),
      name: Value(''),
      type: Value(_type.name),
      curr: Value(_curr),
      updatedAt: Value(DateTime.now()),
      lastPulledAt: Value(_lastPulledAt),
      deleted: Value(false)
    ));
    SyncService().addJob(SyncJob(remote: false));
  }
  Device.fromEntry(DeviceEntry entry)
      : _id = entry.id,
        _type = DeviceType.values.byName(entry.type),
        _curr = entry.curr,
        _lastPulledAt = entry.lastPulledAt;

  String get id => _id;
  DeviceType get type => _type;
  bool get curr => _curr;
  DateTime? get lastPulledAt => _lastPulledAt;

  Future<void> setLastPulledAt(DateTime lastPulledAt) async {
    _lastPulledAt = lastPulledAt;
    await save();
  }
}