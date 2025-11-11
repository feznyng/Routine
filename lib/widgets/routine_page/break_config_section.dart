import 'package:flutter/material.dart';
import '../../models/routine.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../common/mobile_required_callout.dart';

class BreakConfigSection extends StatelessWidget {
  final Routine routine;
  final Function() onChanged;
  final bool enabled;

  const BreakConfigSection({
    super.key,
    required this.routine,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Breaks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max Breaks'),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'none',
                            label: Text('None'),
                          ),
                          ButtonSegment(
                            value: 'unlimited',
                            label: Text('Unlimited'),
                          ),
                          ButtonSegment(
                            value: 'limited',
                            label: Text('Limited'),
                          ),
                        ],
                        selected: {
                          if (routine.maxBreaks == 0) 'none'
                          else if (routine.maxBreaks == null) 'unlimited'
                          else 'limited'
                        },
                        onSelectionChanged: enabled ? (Set<String> selection) {
                          final selected = selection.first;
                          if (selected == 'none') {
                            routine.maxBreaks = 0;
                          } else if (selected == 'unlimited') {
                            routine.maxBreaks = null;
                          } else { // limited
                            routine.maxBreaks = 3;
                          }
                          onChanged();
                        } : null,
                      ),
                    ),
                    if (routine.maxBreaks != null && routine.maxBreaks != 0) ...[                
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'minus',
                              icon: const Icon(Icons.remove),
                              enabled: enabled && routine.maxBreaks! > 1,
                            ),
                            ButtonSegment(
                              value: 'text',
                              label: Text('${routine.maxBreaks} break${(routine.maxBreaks ?? 1) > 1 ? 's' : ''}'),
                            ),
                            ButtonSegment(
                              value: 'plus',
                              icon: const Icon(Icons.add),
                              enabled: enabled && routine.maxBreaks! < 10,
                            ),
                          ],
                          emptySelectionAllowed: true,
                          selected: const {},
                          onSelectionChanged: enabled ? (Set<String> selected) {
                            if (selected.first == 'minus' && routine.maxBreaks! > 1) {
                              routine.maxBreaks = routine.maxBreaks! - 1;
                            } else if (selected.first == 'plus' && routine.maxBreaks! < 10) {
                              routine.maxBreaks = routine.maxBreaks! + 1;
                            }
                            onChanged();
                          } : null,
                        ),
                      ),
                    ],
                    if (routine.maxBreaks != 0) ...[                
                      const SizedBox(height: 16),
                      const Text('Break Duration'),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'minus',
                              icon: const Icon(Icons.remove),
                              enabled: enabled && routine.maxBreakDuration > 5,
                            ),
                            ButtonSegment(
                              value: 'text',
                              label: Text('${routine.maxBreakDuration} min'),
                            ),
                            ButtonSegment(
                              value: 'plus',
                              icon: const Icon(Icons.add),
                              enabled: enabled && routine.maxBreakDuration < 60,
                            ),
                          ],
                          emptySelectionAllowed: true,
                          selected: const {},
                          onSelectionChanged: enabled ? (Set<String> selected) {
                            if (selected.first == 'minus' && routine.maxBreakDuration > 5) {
                              routine.maxBreakDuration = routine.maxBreakDuration - 5;
                            } else if (selected.first == 'plus' && routine.maxBreakDuration < 60) {
                              routine.maxBreakDuration = routine.maxBreakDuration + 5;
                            }
                            onChanged();
                          } : null,
                        ),
                      ),
                    ],
                    if (routine.maxBreaks != 0) ...[                
                      const SizedBox(height: 16),
                      const Text('Friction'),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'none',
                              label: Text('None'),
                            ),
                            ButtonSegment(
                              value: 'delay',
                              label: Text('Delay'),
                            ),
                            ButtonSegment(
                              value: 'pomodoro',
                              label: Text('Pomodoro'),
                            ),
                            ButtonSegment(
                              value: 'intention',
                              label: Text('Intention'),
                            ),
                            ButtonSegment(
                              value: 'code',
                              label: Text('Code'),
                            ),
                            ButtonSegment(
                              value: 'qr',
                              label: Text('QR Code'),
                            ),
                            ButtonSegment(
                              value: 'nfc',
                              label: Text('NFC'),
                            ),
                          ],
                          selected: {routine.friction},
                          onSelectionChanged: enabled ? (Set<String> selection) {
                            routine.friction = selection.first;
                            if (routine.friction == 'none' || 
                                routine.friction == 'intention') {
                              routine.frictionLen = null;
                            }
                            onChanged();
                          } : null,
                        ),
                      ),
                      if (routine.friction != 'none') ...[                
                        const SizedBox(height: 10),
                        Text(
                          routine.friction == 'delay'
                              ? 'Wait a bit before taking a break. Can be fixed or increase with each break.'
                              : routine.friction == 'pomodoro'
                                  ? 'Wait a specified number of minutes from the start of the routine or the end of the last break.'
                                  : routine.friction == 'intention'
                                      ? 'Describe why you want to take a break before taking one.'
                                      : routine.friction == 'code'
                                          ? 'Enter a random code to take a break. Code length can increase with each break or be fixed.'
                                          : routine.friction == 'qr'
                                              ? 'Scan a QR code to take a break.'
                                              : 'Scan an NFC tag to take a break.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                    if (routine.maxBreaks != 0 && routine.friction == 'nfc') ...[                
                      const SizedBox(height: 16),
                      if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) ...[                
                        const MobileRequiredCallout(feature: 'NFC scanning'),
                        const SizedBox(height: 16),
                      ],
                      TextButton.icon(
                        onPressed: enabled ? () async {
                          if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('NFC is only supported on mobile devices. Please use a mobile device to scan a tag.'),
                              ),
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
                            NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
                              try {
                                bool writeSuccess = false;
                                if (tag.data.containsKey('ndef')) {
                                  final ndef = Ndef.from(tag);
                                  if (ndef != null && ndef.isWritable) {
                                    final message = NdefMessage([
                                      NdefRecord.createText(routine.id),
                                    ]);
                                    await ndef.write(message);
                                    writeSuccess = true;
                                  }
                                }

                                if (writeSuccess) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Successfully scanned NFC tag ✓'),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to scan NFC Tag ✗'),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error scanning NFC tag: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                NfcManager.instance.stopSession();
                              }
                            });
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error starting NFC: $e'),
                                ),
                              );
                            }
                          }
                        } : null,
                        icon: const Icon(Icons.nfc),
                        label: const Text('Scan Tag'),
                      ),
                    ],
                    if (routine.maxBreaks != 0 && routine.friction == 'qr') ...[                
                      const SizedBox(height: 16),
                      if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) ...[                
                        const MobileRequiredCallout(feature: 'QR code scanning'),
                        const SizedBox(height: 16),
                      ],
                      TextButton.icon(
                        onPressed: () async {
                          final path = await getSaveLocation(
                            suggestedName: '${routine.name.toLowerCase().replaceAll(' ', '_')}_qr.png',
                            acceptedTypeGroups: [
                              const XTypeGroup(label: 'PNG', extensions: ['png']),
                            ],
                          );
                          if (path == null) return;
                          final painter = QrPainter(
                            data: routine.id,
                            version: QrVersions.auto,
                            gapless: true,
                            errorCorrectionLevel: QrErrorCorrectLevel.L,
                          );
                          final imageData = await painter.toImageData(600.0);
                          if (imageData == null) return;
                          final file = XFile.fromData(
                            imageData.buffer.asUint8List(),
                            mimeType: 'image/png',
                            name: path.path.split('/').last,
                          );
                          await file.saveTo(path.path);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download QR Code'),
                      ),
                    ],
                    if (routine.maxBreaks != 0 && (routine.friction == 'delay' || routine.friction == 'code')) ...[                
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(routine.friction == 'delay' 
                              ? 'Delay Length' 
                              : 'Code Length'),
                          const SizedBox(width: 8)
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Automatic'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Fixed'),
                            ),
                          ],
                          selected: {routine.frictionLen != null},
                          onSelectionChanged: enabled ? (Set<bool> selection) {
                            routine.frictionLen = selection.first 
                              ? (routine.friction == 'delay' 
                                  ? 30 
                                  : 6)
                               : null;
                            onChanged();
                          } : null,
                        ),
                      ),
                      if (routine.frictionLen != null) ...[                

                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'minus',
                                icon: const Icon(Icons.remove),
                                enabled: enabled && routine.frictionLen! > (routine.friction == 'delay' ? 5 : routine.friction == 'pomodoro' ? 5 : 4),
                              ),
                              ButtonSegment(
                                value: 'text',
                                label: Text(routine.friction == 'delay' 
                                  ? '${routine.frictionLen} sec'
                                  : routine.friction == 'pomodoro'
                                      ? '${routine.frictionLen} min'
                                      : '${routine.frictionLen}'),
                              ),
                              ButtonSegment(
                                value: 'plus',
                                icon: const Icon(Icons.add),
                                enabled: enabled && routine.frictionLen! < (routine.friction == 'delay' ? 60 : routine.friction == 'pomodoro' ? 120 : 20),
                              ),
                            ],
                            emptySelectionAllowed: true,
                            selected: const {},
                            onSelectionChanged: enabled ? (Set<String> selected) {
                              if (selected.first == 'minus' && 
                                  routine.frictionLen! > (routine.friction == 'delay' ? 5 : routine.friction == 'pomodoro' ? 5 : 4)) {
                                routine.frictionLen = routine.frictionLen! - (routine.friction == 'delay' ? 5 : routine.friction == 'pomodoro' ? 5 : 1);
                              } else if (selected.first == 'plus' && 
                                  routine.frictionLen! < (routine.friction == 'delay' ? 60 : routine.friction == 'pomodoro' ? 120 : 20)) {
                                routine.frictionLen = routine.frictionLen! + (routine.friction == 'delay' ? 5 : routine.friction == 'pomodoro' ? 5 : 1);
                              }
                              onChanged();
                            } : null,
                          ),
                        ),
                      ],
                    ],
                    if (routine.maxBreaks != 0 && routine.friction == 'pomodoro') ...[                
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Work Duration'),
                          const SizedBox(width: 8)
                        ],
                      ),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        if (routine.frictionLen == null) {
                          Future.microtask(() {
                            routine.frictionLen = 25;
                            onChanged();
                          });
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'minus',
                                icon: const Icon(Icons.remove),
                                enabled: enabled && (routine.frictionLen ?? 25) > 5,
                              ),
                              ButtonSegment(
                                value: 'text',
                                label: Text('${routine.frictionLen ?? 25} min'),
                              ),
                              ButtonSegment(
                                value: 'plus',
                                icon: const Icon(Icons.add),
                                enabled: enabled && (routine.frictionLen ?? 25) < 120,
                              ),
                            ],
                            emptySelectionAllowed: true,
                            selected: const {},
                            onSelectionChanged: enabled ? (Set<String> selected) {
                              if (selected.first == 'minus' && 
                                  (routine.frictionLen ?? 25) > 5) {
                                routine.frictionLen = (routine.frictionLen ?? 25) - 5;
                              } else if (selected.first == 'plus' && 
                                  (routine.frictionLen ?? 25) < 120) {
                                routine.frictionLen = (routine.frictionLen ?? 25) + 5;
                              }
                              onChanged();
                            } : null,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
