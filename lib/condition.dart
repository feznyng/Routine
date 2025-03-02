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

  bool _modified = false;

  Condition({required this.id, required ConditionType type, double? latitude, double? longitude, double? proximity, String? nfcQrCode, String? activityType, String? activityAmt, String? name, DateTime? completedAt})
      : _type = type,
        _latitude = latitude,
        _longitude = longitude,
        _proximity = proximity,
        _nfcQrCode = nfcQrCode,
        _activityType = activityType,
        _activityAmt = activityAmt,
        _name = name,
        _lastCompletedAt = completedAt;

  Condition.create({required ConditionType type, String? name}) 
      : id = Uuid().v4(),
        _type = type,
        _name = name;

  // Getters
  bool get modified => _modified;
  ConditionType get type => _type;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  double? get proximity => _proximity;
  String? get nfcQrCode => _nfcQrCode;
  String? get activityType => _activityType;
  String? get activityAmt => _activityAmt;
  String? get name => _name;
  DateTime? get lastCompletedAt => _lastCompletedAt;

  // Setters
  set type(ConditionType value) {
    _type = value;
    _modified = true;
  }

  set latitude(double? value) {
    _latitude = value;
    _modified = true;
  }

  set longitude(double? value) {
    _longitude = value;
    _modified = true;
  }

  set proximity(double? value) {
    _proximity = value;
    _modified = true;
  }

  set nfcQrCode(String? value) {
    _nfcQrCode = value;
    _modified = true;
  }

  set activityType(String? value) {
    _activityType = value;
    _modified = true;
  }

  set activityAmt(String? value) {
    _activityAmt = value;
    _modified = true;
  }

  set name(String? value) {
    _name = value;
    _modified = true;
  }

  set lastCompletedAt(DateTime? value) {
    _lastCompletedAt = value;
    _modified = true;
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
    );
    
    // Handle legacy data that might have a name field
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