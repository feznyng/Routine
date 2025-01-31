enum DeviceType {
  windows,
  linux,
  macos,
  ios,
  android
}

class Device {
  final String _id;
  final DeviceType _type;

  Device({required String id, required DeviceType type})
      : _id = id,
        _type = type;

  String get id => _id;
  DeviceType get type => _type;
}