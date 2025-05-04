import 'package:flutter/material.dart';
import '../../models/condition.dart';

class ConditionTypeUtils {
  static String getLabel(ConditionType type) {
    switch (type) {
      case ConditionType.location:
        return 'Location';
      case ConditionType.nfc:
        return 'NFC Tag';
      case ConditionType.qr:
        return 'QR Code';
      case ConditionType.health:
        return 'Health Activity';
      case ConditionType.todo:
        return 'To-Do Task';
    }
  }

  static IconData getIcon(ConditionType type) {
    switch (type) {
      case ConditionType.location:
        return Icons.location_on;
      case ConditionType.nfc:
        return Icons.nfc;
      case ConditionType.qr:
        return Icons.qr_code;
      case ConditionType.health:
        return Icons.fitness_center;
      case ConditionType.todo:
        return Icons.check_circle_outline;
    }
  }
}
