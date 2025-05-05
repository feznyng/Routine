// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// Condition _$ConditionFromJson(Map<String, dynamic> json) => Condition(
//       id: json['id'] as String,
//       type: $enumDecode(_$ConditionTypeEnumMap, json['type']),
//       latitude: (json['latitude'] as num?)?.toDouble(),
//       longitude: (json['longitude'] as num?)?.toDouble(),
//       proximity: (json['proximity'] as num?)?.toDouble(),
//       nfcQrCode: json['nfcQrCode'] as String?,
//       activityType: json['activityType'] as String?,
//       activityAmt: json['activityAmt'] as String?,
//       name: json['name'] as String?,
//     )..lastCompletedAt = json['lastCompletedAt'] == null
//         ? null
//         : DateTime.parse(json['lastCompletedAt'] as String);

// Map<String, dynamic> _$ConditionToJson(Condition instance) => <String, dynamic>{
//       'id': instance.id,
//       'type': _$ConditionTypeEnumMap[instance.type]!,
//       'latitude': instance.latitude,
//       'longitude': instance.longitude,
//       'proximity': instance.proximity,
//       'nfcQrCode': instance.nfcQrCode,
//       'activityType': instance.activityType,
//       'activityAmt': instance.activityAmt,
//       'name': instance.name,
//       'lastCompletedAt': instance.lastCompletedAt?.toIso8601String(),
//     };

const _$ConditionTypeEnumMap = {
  ConditionType.location: 'location',
  ConditionType.nfc: 'nfc',
  ConditionType.qr: 'qr',
  ConditionType.health: 'health',
  ConditionType.todo: 'todo',
};
