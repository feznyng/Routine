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
  late String _name;
  final String _id;
  late final DeviceType _type;
  late final bool _curr;
  late DateTime? _lastPulledAt;

  static Future<Device> getCurrent() async {
    final deviceEntry = await getIt<AppDatabase>().getThisDevice();
    print('currDevice $deviceEntry');

    if (deviceEntry != null) {
      return Device.fromEntry(deviceEntry);
    } else {
      final device =  Device(currDevice: true);
      await device._save();
      return device;
    }
  }

  Device({bool currDevice = false}) : _id = const Uuid().v4() {
    _name = "";
    if (Platform.isMacOS) {
      _name = "Macbook";
      _type = DeviceType.macos;
    } else if (Platform.isLinux) {
      _name = "Linux";
      _type = DeviceType.linux;
    } else if (Platform.isWindows) {
      _name = "Windows";
      _type = DeviceType.windows;
    } else if (Platform.isIOS) {
      _name = "iPhone";
      _type = DeviceType.ios;
    } else if (Platform.isAndroid) {
      _name = "Android";
      _type = DeviceType.android;
    } else {
      throw Exception('Unsupported platform');
    }
    _lastPulledAt = null;
    _curr = currDevice;
  }
  
  Future<void> _save() async {
    await getIt<AppDatabase>().upsertDevice(DevicesCompanion(
      id: Value(_id),
      name: Value(_name),
      type: Value(_type.name),
      curr: Value(_curr),
      updatedAt: Value(DateTime.now()),
      deleted: Value(false),
      changes: Value(const []),
    ));

    print('device save sync');
    SyncService().addJob(SyncJob(remote: false));
  }
  Device.fromEntry(DeviceEntry entry)
      : _id = entry.id,
        _type = DeviceType.values.byName(entry.type),
        _curr = entry.curr;

  String get id => _id;
  DeviceType get type => _type;
  bool get curr => _curr;
  DateTime? get lastPulledAt => _lastPulledAt;
}