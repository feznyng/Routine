
import 'package:uuid/uuid.dart';

class EmergencyEvent {
  final String id;
  final DateTime startedAt;
  DateTime? _endedAt;

  DateTime? get endedAt => _endedAt;
  set endedAt(DateTime? value) {
    if (_endedAt != null) return; // Can only set once
    _endedAt = value;
  }

  EmergencyEvent({
    required this.startedAt,
    DateTime? endedAt,
  }) : id = const Uuid().v4(),
      _endedAt = endedAt;

  EmergencyEvent.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      startedAt = DateTime.parse(json['started_at']),
      _endedAt = json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'started_at': startedAt.toUtc().toIso8601String(),
    if (_endedAt != null)
      'ended_at': _endedAt!.toUtc().toIso8601String(),
  };

  bool get isActive => endedAt == null;

  @override
  String toString() {
    return 'EmergencyEvent(id: $id, startedAt: $startedAt, endedAt: $endedAt, isActive: $isActive)';
  }
}
