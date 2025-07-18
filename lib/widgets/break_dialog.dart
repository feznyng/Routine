import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/routine.dart';
import 'dart:io' show Platform;
import '../pages/qr_scanner_page.dart';
import 'package:nfc_manager/nfc_manager.dart';

class BreakDialog extends StatefulWidget {
  final Routine routine;

  const BreakDialog({
    super.key,
    required this.routine,
  });

  @override
  State<BreakDialog> createState() => _BreakDialogState();
}

class _BreakDialogState extends State<BreakDialog> {
  final _codeController = TextEditingController();
  Timer? _delayTimer;
  Timer? _pomodoroTimer;
  late int breakDuration;
  bool canConfirm = false;
  String? _scanFeedback;
  int? remainingDelay;
  int? remainingPomodoroSeconds;
  String? generatedCode;

  @override
  void initState() {
    super.initState();
    canConfirm = widget.routine.friction == 'none' || 
                (widget.routine.friction == 'pomodoro' && widget.routine.canTakeBreakNowWithPomodoro);

    breakDuration = min(15, widget.routine.maxBreakDuration);

    if (widget.routine.friction == 'code') {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();

      final codeLength = widget.routine.frictionLen ?? widget.routine.calculateCodeLength();
      generatedCode = List.generate(codeLength, (index) => chars[random.nextInt(chars.length)]).join();
    } else if (widget.routine.friction == 'delay') {
      remainingDelay = widget.routine.frictionLen ?? 30;
      _startDelayTimer();
    } else if (widget.routine.friction == 'pomodoro') {
      // Initialize Pomodoro timer if needed
      if (!widget.routine.canTakeBreakNowWithPomodoro) {
        final remainingSeconds = widget.routine.getRemainingPomodoroTime;
        if (remainingSeconds > 0) {
          remainingPomodoroSeconds = remainingSeconds;
          _startPomodoroTimer();
        }
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _delayTimer?.cancel();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  void _startDelayTimer() {
    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (remainingDelay! > 0) {
          remainingDelay = remainingDelay! - 1;
        } else {
          canConfirm = true;
          timer.cancel();
        }
      });
    });
  }
  
  void _startPomodoroTimer() {
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (remainingPomodoroSeconds! > 0) {
          remainingPomodoroSeconds = remainingPomodoroSeconds! - 1;
        } else {
          canConfirm = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      title: const Text('Take a Break'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always show breaks information
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.routine.breaksLeftText} break${widget.routine.numBreaksLeft == 1 ? '' : 's'} left',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'minus',
                icon: const Icon(Icons.remove),
                enabled: breakDuration > 5,
              ),
              ButtonSegment(
                value: 'text',
                label: Text('$breakDuration min'),
              ),
              ButtonSegment(
                value: 'plus',
                icon: const Icon(Icons.add),
                enabled: breakDuration < widget.routine.maxBreakDuration,
              ),
            ],
            emptySelectionAllowed: true,
            selected: const {},
            onSelectionChanged: (Set<String> selected) {
              setState(() {
                if (selected.first == 'minus' && breakDuration > 5) {
                  breakDuration = breakDuration - 5;
                } else if (selected.first == 'plus' && breakDuration < widget.routine.maxBreakDuration) {
                  breakDuration = breakDuration + 5;
                }
              });
            },
          ),
          if (widget.routine.friction != 'none') ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (widget.routine.friction == 'delay' && remainingDelay! > 0) ...[
              Text('Wait $remainingDelay ${remainingDelay == 1 ? 'second' : 'seconds'}'),
            ] else if (widget.routine.friction == 'pomodoro') ...[              
              Builder(builder: (context) {
                // Use the state variable if available, otherwise get directly from the routine
                final int remainingSeconds = remainingPomodoroSeconds ?? widget.routine.getRemainingPomodoroTime;
                final int minutes = remainingSeconds ~/ 60;
                final int seconds = remainingSeconds % 60;
                
                if (remainingSeconds > 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pomodoro',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: SizedBox(
                          height: 160,
                          width: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background circle
                              Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Progress indicator
                              SizedBox(
                                height: 150,
                                width: 150,
                                child: CircularProgressIndicator(
                                  value: widget.routine.frictionLen != null && widget.routine.frictionLen! > 0 ?
                                    1 - (remainingSeconds / (widget.routine.frictionLen! * 60)) : 0,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  strokeWidth: 10.0,
                                ),
                              ),
                              // Inner circle with time display
                              Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'remaining',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pomodoro',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ready',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              }),
            ] else if (widget.routine.friction == 'intention') ...[
              const Text('What will you do during this break?'),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) => setState(() {
                  canConfirm = value.trim().length >= 10;
                }),
                decoration: const InputDecoration(
                  hintText: 'Write at least 10 characters',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (widget.routine.friction == 'code') ...[
              Text('Type this code: $generatedCode'),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                onChanged: (value) => setState(() {
                  canConfirm = value == generatedCode;
                }),
                decoration: const InputDecoration(
                  hintText: 'Type the code above',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
            ] else if (widget.routine.friction == 'qr') ...[
              if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) ...[
                const Text(
                  'Please use your phone to scan the QR code.',
                  style: TextStyle(fontSize: 16),
                ),
              ] else ...[
                if (!canConfirm) ...[
                  const Text('Scan the QR code to start your break'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QrScannerPage(
                            onCodeScanned: (code) {
                              if (code == widget.routine.id) {
                                setState(() {
                                  canConfirm = true;
                                  _scanFeedback = 'QR code verified ✓';
                                });
                              } else {
                                setState(() {
                                  _scanFeedback = 'Invalid QR code ✗';
                                });
                              }
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                  ),
                ],
              ],
            ] else if (widget.routine.friction == 'nfc') ...[
              if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) ...[
                const Text(
                  'Please use your phone to scan the NFC tag.',
                  style: TextStyle(fontSize: 16),
                ),
              ] else ...[
                if (!canConfirm) ...[
                  const Text('Scan the NFC tag to start your break'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
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

                        // Start NFC session
                        NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
                          try {
                            if (tag.data.containsKey('ndef')) {
                              final ndef = Ndef.from(tag);
                              if (ndef != null) {
                                final message = await ndef.read();
                                final record = message.records.first;
                                final payload = String.fromCharCodes(record.payload).substring(3); // Skip language code
                                
                                if (payload == widget.routine.id) {
                                  setState(() {
                                    canConfirm = true;
                                    _scanFeedback = 'NFC tag verified ✓';
                                  });
                                } else {
                                  setState(() {
                                    _scanFeedback = 'Invalid NFC tag ✗';
                                  });
                                }
                              }
                            }
                          } catch (e) {
                            setState(() {
                              _scanFeedback = 'Error reading NFC tag: $e';
                            });
                          } finally {
                            NfcManager.instance.stopSession();
                          }
                        });
                      } catch (e) {
                        setState(() {
                          _scanFeedback = 'Error starting NFC: $e';
                        });
                      }
                    },
                    icon: const Icon(Icons.nfc),
                    label: const Text('Scan NFC Tag'),
                  ),
                ],
              ],
            ],
            if (_scanFeedback != null) ...[                  
              const SizedBox(height: 8),
              Text(
                _scanFeedback!,
                style: TextStyle(
                  color: canConfirm ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
          ]
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: canConfirm ? () async {
            await widget.routine.breakFor(minutes: breakDuration);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } : null,
          child: const Text('Start Break'),
        ),
      ],
    );
  }
}
