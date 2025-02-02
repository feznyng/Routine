import 'package:uuid/uuid.dart';
import 'dart:io';
import 'database.dart';
import 'setup.dart';

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
  late final bool _currDevice;

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

    _currDevice = currDevice;
  }
  
  Future<void> save() async {
    await getIt<AppDatabase>().insertDevice(DeviceEntry(id: _id, name: '', type: _type.name, thisDevice: true));
  }

  Device.fromEntry(DeviceEntry entry)
      : _id = entry.id,
        _type = DeviceType.values.byName(entry.type),
        _currDevice = entry.thisDevice
        ;

  String get id => _id;
  DeviceType get type => _type;
  bool get currDevice => _currDevice;
}