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

@JsonSerializable()
class Condition {
  late final String id;
  late final ConditionType _type;
  late final String? _location;
  late final String? _nfcQrCode;
  late final String? _activityType;
  late final String? _activityAmt;
  late final String? _todoText;
  late final DateTime? _lastCompletedAt;

  bool _modified = false;

  Condition({required this.id, required ConditionType type, String? location, String? nfcQrCode, String? activityType, String? activityAmt, String? todoText, DateTime? completedAt})
      : _type = type,
        _location = location,
        _nfcQrCode = nfcQrCode,
        _activityType = activityType,
        _activityAmt = activityAmt,
        _todoText = todoText,
        _lastCompletedAt = completedAt;

  Condition.create({required ConditionType type}) 
      : id = Uuid().v4(),
        _type = type;

  // Getters
  bool get modified => _modified;
  ConditionType get type => _type;
  String? get location => _location;
  String? get nfcQrCode => _nfcQrCode;
  String? get activityType => _activityType;
  String? get activityAmt => _activityAmt;
  String? get todoText => _todoText;
  DateTime? get lastCompletedAt => _lastCompletedAt;

  // Setters
  set type(ConditionType value) {
    _type = value;
    _modified = true;
  }

  set location(String? value) {
    _location = value;
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

  set todoText(String? value) {
    _todoText = value;
    _modified = true;
  }

  set lastCompletedAt(DateTime? value) {
    _lastCompletedAt = value;
    _modified = true;
  }

  factory Condition.fromJson(Map<String, dynamic> json) => _$ConditionFromJson(json);

  Map<String, dynamic> toJson() => _$ConditionToJson(this);
}


class ConditionConverter extends TypeConverter<List<Condition>, String> with
        JsonTypeConverter2<List<Condition>, String, List<Map<String, Object?>>> {
  const ConditionConverter();

  @override
  List<Condition> fromSql(String fromDb) {
    return fromJson(json.decode(fromDb) as List<Map<String, dynamic>>);
  }

  @override
  String toSql(List<Condition> value) {
    return json.encode(toJson(value));
  }

  @override
  List<Condition> fromJson(List<Map<String, Object?>> json) {
    return json.map((map) => Condition.fromJson(Map<String, dynamic>.from(map))).toList();
  }

  @override
  List<Map<String, Object?>> toJson(List<Condition> value) {
    return value.map((condition) => condition.toJson()).toList();
  }
}