import 'package:flutter/material.dart';

/// Intention friction display widget
class IntentionFrictionDisplay extends StatelessWidget {
  final ValueChanged<bool> onCanConfirmChanged;

  const IntentionFrictionDisplay({
    super.key,
    required this.onCanConfirmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Break Intention',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What will you do during this break?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => onCanConfirmChanged(value.trim().length >= 10),
          decoration: InputDecoration(
            hintText: 'Write at least 10 characters...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
