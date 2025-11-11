import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../models/routine.dart';
import '../../pages/qr_scanner_page.dart';


class QrFrictionDisplay extends StatelessWidget {
  final Routine routine;
  final bool canConfirm;
  final String? scanFeedback;
  final ValueChanged<bool> onCanConfirmChanged;
  final ValueChanged<String?> onScanFeedbackChanged;

  const QrFrictionDisplay({
    super.key,
    required this.routine,
    required this.canConfirm,
    required this.scanFeedback,
    required this.onCanConfirmChanged,
    required this.onScanFeedbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code Verification',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) ...[
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.smartphone,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please use your phone to scan the QR code.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          if (!canConfirm) ...[
            Text(
              'Scan the QR code to start your break',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrScannerPage(
                        onCodeScanned: (code) {
                          if (code == routine.id) {
                            onCanConfirmChanged(true);
                            onScanFeedbackChanged('QR code verified ✓');
                          } else {
                            onScanFeedbackChanged('Invalid QR code ✗');
                          }
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
        if (scanFeedback != null) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: canConfirm 
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    canConfirm ? Icons.check_circle : Icons.error,
                    color: canConfirm 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    scanFeedback!,
                    style: TextStyle(
                      color: canConfirm 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
