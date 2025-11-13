import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nfc_manager/ndef_record.dart';
import 'dart:io' show Platform;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import '../../../models/condition.dart';
import '../../common/mobile_required_callout.dart';

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
        if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux))
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MobileRequiredCallout(feature: 'NFC scanning'),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.nfc),
                label: Text('Scan NFC Tag'),
                onPressed: _name == null || _name!.isEmpty ? null : () async {
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
                    NfcManager.instance.startSession(pollingOptions: HashSet.of(NfcPollingOption.values), onDiscovered: (NfcTag tag) async {
                      try {
                        bool writeSuccess = false;
                        final ndef = Ndef.from(tag);
                        if (ndef != null && ndef.isWritable) {
                          final message = NdefMessage(records: [
                            NdefRecord(typeNameFormat: TypeNameFormat.wellKnown, type: Uint8List.fromList([0x54]), identifier: Uint8List.fromList(widget.condition.data.codeUnits), payload: Uint8List.fromList(widget.condition.data.codeUnits)),
                          ]);
                          
                          await ndef.write(message: message);
                          writeSuccess = true;
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
