import 'package:flutter/material.dart';
import '../../models/routine.dart';

class StrictModeSection extends StatelessWidget {
  final Routine routine;
  final VoidCallback onChanged;
  final bool enabled;

  const StrictModeSection({
    super.key,
    required this.routine,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Text(
                  'Strict Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Switch(
                  value: routine.strictMode,
                  onChanged: enabled ? (value) {
                    routine.strictMode = value;
                    onChanged();
                  } : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'When strict mode is enabled, this routine cannot be paused, deleted, or snoozed, and breaks cannot be taken outside of the configured limits.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
