import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:nfc_manager/nfc_manager.dart';
import '../../../models/condition.dart';

class NfcConditionWidget extends StatefulWidget {
  final Condition condition;
  final TextEditingController nameController;
  final Function(String, {bool isSuccess, bool isError}) onStatusMessage;

  const NfcConditionWidget({
    super.key,
    required this.condition,
    required this.nameController,
    required this.onStatusMessage,
  });

  @override
  State<NfcConditionWidget> createState() => _NfcConditionWidgetState();
}

class _NfcConditionWidgetState extends State<NfcConditionWidget> {
  String? _name;

  @override
  void initState() {
    super.initState();
    _name = widget.nameController.text;
    widget.nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _name = widget.nameController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'The condition name will be written to the NFC tag. You can use the same tag in another condition by entering the same name.',
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.nfc),
                label: Text('Scan NFC Tag'),
                onPressed: _name == null || _name!.isEmpty ? null : () async {
                  // Check if we're on desktop
                  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
                    widget.onStatusMessage(
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
                              NdefRecord.createText(widget.condition.data),
                            ]);
                            
                            await ndef.write(message);
                            writeSuccess = true;
                          }
                        }

                        if (context.mounted) {
                          widget.onStatusMessage(
                            writeSuccess 
                              ? 'NFC tag successfully scanned' 
                              : 'NFC tag scanned but could not write data. Please try another tag.',
                            isSuccess: writeSuccess,
                            isError: !writeSuccess
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          widget.onStatusMessage('Error processing NFC tag: $e', isError: true);
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
