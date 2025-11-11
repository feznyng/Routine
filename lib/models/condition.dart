import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import 'package:drift/drift.dart' show TypeConverter, JsonTypeConverter2;
part 'condition.g.dart';

enum ConditionType {
  location,
  nfc,
  qr,
  health,
  todo
}

@JsonSerializable(explicitToJson: true)
class Condition {
  String id;
  ConditionType _type;
  double? _latitude;
  double? _longitude;
  double? _proximity; // in meters
  String? _nfcQrCode;
  String? _activityType;
  String? _activityAmt;
  String? _name; // Used as name/description for all condition types
  DateTime? _lastCompletedAt;
  Map<String, dynamic>? _original;

  Condition({required this.id, required ConditionType type, double? latitude, double? longitude, double? proximity, String? nfcQrCode, String? activityType, String? activityAmt, String? name, DateTime? completedAt, Map<String, dynamic>? original})
      : _type = type,
        _latitude = latitude,
        _longitude = longitude,
        _proximity = proximity,
        _nfcQrCode = nfcQrCode,
        _activityType = activityType,
        _activityAmt = activityAmt,
        _name = name,
        _lastCompletedAt = completedAt,
        _original = original;

  Condition.create({required ConditionType type, String? name}) 
      : id = Uuid().v4(),
        _type = type,
        _name = name,
        _original = null;
  bool get modified {
    if (_original == null) {
      return true;
    }

    final original = Condition.fromJson(_original!);

    return original.type != type ||
      original.latitude != latitude ||
      original.longitude != longitude ||
      original.proximity != proximity ||
      original.nfcQrCode != nfcQrCode ||
      original.activityType != activityType ||
      original.activityAmt != activityAmt ||
      original.name != name ||
      original.lastCompletedAt != lastCompletedAt;
  }
  ConditionType get type => _type;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  double? get proximity => _proximity;
  String? get nfcQrCode => _nfcQrCode;
  


  String get data => name != null ? 'condition:$name' : '';
  String? get activityType => _activityType;
  String? get activityAmt => _activityAmt;
  String? get name => _name;
  DateTime? get lastCompletedAt => _lastCompletedAt;
  set type(ConditionType value) {
    _type = value;
  }

  set latitude(double? value) {
    _latitude = value;
  }

  set longitude(double? value) {
    _longitude = value;
  }

  set proximity(double? value) {
    _proximity = value;
  }

  set nfcQrCode(String? value) {
    _nfcQrCode = value;
  }

  set activityType(String? value) {
    _activityType = value;
  }

  set activityAmt(String? value) {
    _activityAmt = value;
  }

  set name(String? value) {
    _name = value;
  }

  set lastCompletedAt(DateTime? value) {
    _lastCompletedAt = value;
  }

  factory Condition.fromJson(Map<String, dynamic> json) {
    final condition = Condition(
      id: json['id'] as String,
      type: $enumDecode(_$ConditionTypeEnumMap, json['type']),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      proximity: json['proximity'] != null ? (json['proximity'] as num).toDouble() : null,
      nfcQrCode: json['nfcQrCode'] as String?,
      activityType: json['activityType'] as String?,
      activityAmt: json['activityAmt'] as String?,
      name: json['name'] as String?,
      completedAt: json['lastCompletedAt'] == null
        ? null
        : DateTime.parse(json['lastCompletedAt'] as String),
      original: json
    );
    if (json.containsKey('name') && json['name'] != null && condition.name == null) {
      condition.name = json['name'] as String?;
    }
    return condition;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': _$ConditionTypeEnumMap[type]!,
    'latitude': latitude,
    'longitude': longitude,
    'proximity': proximity,
    'nfcQrCode': nfcQrCode,
    'activityType': activityType,
    'activityAmt': activityAmt,
    'name': name,
    'lastCompletedAt': lastCompletedAt?.toIso8601String(),
  };
}

class ConditionConverter extends TypeConverter<List<Condition>, String> with
        JsonTypeConverter2<List<Condition>, String, List<dynamic>> {
  const ConditionConverter();

  @override
  List<Condition> fromSql(String fromDb) {
    return fromJson(json.decode(fromDb) as List<dynamic>);
  }

  @override
  String toSql(List<Condition> value) {
    return json.encode(toJson(value));
  }

  @override
  List<Condition> fromJson(List<dynamic> json) {
    return json.map((map) => Condition.fromJson(Map<String, dynamic>.from(map))).toList();
  }

  @override
  List<dynamic> toJson(List<Condition> value) {
    return value.map((condition) => condition.toJson()).toList();
  }
}