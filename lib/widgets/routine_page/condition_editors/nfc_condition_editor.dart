import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:nfc_manager/nfc_manager.dart';
import '../../../models/condition.dart';

class NfcConditionWidget extends StatelessWidget {
  final Condition condition;
  final Function(String, {bool isSuccess, bool isError}) onStatusMessage;

  const NfcConditionWidget({
    super.key,
    required this.condition,
    required this.onStatusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.nfc),
                label: const Text('Scan NFC Tag'),
                onPressed: () async {
                  // Check if we're on desktop
                  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
                    onStatusMessage(
                      'NFC scanning is only supported on mobile devices. Please use a mobile device.',
                      isError: true
                    );
                    return;
                  }

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

                    // Start NFC session
                    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
                      try {
                        bool writeSuccess = false;
                        if (tag.data.containsKey('ndef')) {
                          final ndef = Ndef.from(tag);
                          if (ndef != null && ndef.isWritable) {
                            final message = NdefMessage([
                              NdefRecord.createText(condition.data),
                            ]);
                            
                            await ndef.write(message);
                            writeSuccess = true;
                          }
                        }

                        if (context.mounted) {
                          onStatusMessage(
                            writeSuccess 
                              ? 'NFC tag successfully scanned' 
                              : 'NFC tag scanned but could not write data. Please try another tag.',
                            isSuccess: writeSuccess,
                            isError: !writeSuccess
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          onStatusMessage('Error processing NFC tag: $e', isError: true);
                        }
                      } finally {
                        NfcManager.instance.stopSession();
                      }
                    });
                  } catch (e) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('Error accessing NFC: $e'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
