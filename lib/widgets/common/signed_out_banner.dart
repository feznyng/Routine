import 'package:flutter/material.dart';

class SignedOutBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const SignedOutBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const Key('signed_out_banner'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'ve been signed out',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your session has expired or was ended remotely. Please sign in again to sync your data.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
