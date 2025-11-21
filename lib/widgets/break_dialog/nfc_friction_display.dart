import 'package:routine_blocker/util.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:nfc_manager/nfc_manager.dart';
import '../../models/routine.dart';


class NfcFrictionDisplay extends StatelessWidget {
  final Routine routine;
  final bool canConfirm;
  final String? scanFeedback;
  final ValueChanged<bool> onCanConfirmChanged;
  final ValueChanged<String?> onScanFeedbackChanged;

  const NfcFrictionDisplay({
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
          'NFC Tag Verification',
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
                      'Please use your phone to scan the NFC tag.',
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
              'Scan the NFC tag to start your break',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    bool isAvailable = await NfcManager.instance.isAvailable();
                    if (!isAvailable) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('NFC Not Available'),
                            content: const Text('NFC is not available on this device.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                      return;
                    }

                    Util.readNfcTag((String? tagData) async {
                      if (tagData != null) {
                        if (tagData == routine.id) {
                          onCanConfirmChanged(true);
                          onScanFeedbackChanged('NFC tag verified ✓');
                        } else {
                          onScanFeedbackChanged('Invalid NFC tag ✗');
                        }
                      } else {
                        onScanFeedbackChanged('No data found on this NFC tag. Please try scanning again.');
                      }
                    });
                  } catch (e) {
                    onScanFeedbackChanged('Error starting NFC: $e');
                  }
                },
                icon: const Icon(Icons.nfc),
                label: const Text('Scan NFC Tag'),
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
