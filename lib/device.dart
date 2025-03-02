import 'package:drift/drift.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
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

    if (deviceEntry != null) {
      return Device.fromEntry(deviceEntry);
    } else {
      final device = await Device.create(currDevice: true);
      await device._save();
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

  void _initDeviceType() {
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
        
  static Future<String> _generateDeviceHash() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isMacOS) {
      final iosData = await deviceInfo.macOsInfo;
      deviceId = '${iosData.systemGUID};';
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

  String get id => _id;
  DeviceType get type => _type;
  bool get curr => _curr;
  DateTime? get lastPulledAt => _lastPulledAt;
}