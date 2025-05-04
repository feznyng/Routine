import 'package:flutter/material.dart';
import '../../../models/condition.dart';

class HealthConditionWidget extends StatelessWidget {
  final Condition condition;
  final TextEditingController activityTypeController;
  final TextEditingController activityAmtController;

  const HealthConditionWidget({
    super.key,
    required this.condition,
    required this.activityTypeController,
    required this.activityAmtController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: activityTypeController,
          decoration: const InputDecoration(
            labelText: 'Activity Type',
            hintText: 'E.g., Steps, Running, etc.',
          ),
          onChanged: (value) {
            condition.activityType = value;
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: activityAmtController,
          decoration: const InputDecoration(
            labelText: 'Activity Amount',
            hintText: 'E.g., 5000 steps, 30 minutes, etc.',
          ),
          onChanged: (value) {
            condition.activityAmt = value;
          },
        ),
      ],
    );
  }
}
