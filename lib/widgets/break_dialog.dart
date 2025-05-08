import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/routine.dart';
import '../database/database.dart';

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
  int breakDuration = 15;
  bool canConfirm = false;
  int? remainingDelay;
  String? generatedCode;

  @override
  void initState() {
    super.initState();
    canConfirm = widget.routine.friction == FrictionType.none;

    if (widget.routine.friction == FrictionType.code) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();

      final codeLength = widget.routine.frictionLen ?? widget.routine.calculateCodeLength();
      generatedCode = List.generate(codeLength, (index) => chars[random.nextInt(chars.length)]).join();
    } else if (widget.routine.friction == FrictionType.delay) {
      remainingDelay = widget.routine.frictionLen ?? 30;
      _startDelayTimer();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _delayTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      title: const Text('Take a Break'),
      content: Column(
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
          if (widget.routine.friction != FrictionType.none) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (widget.routine.friction == FrictionType.delay && remainingDelay! > 0) ...[
              Text('Wait $remainingDelay ${remainingDelay == 1 ? 'second' : 'seconds'}'),
            ] else if (widget.routine.friction == FrictionType.intention) ...[
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
            ] else if (widget.routine.friction == FrictionType.code) ...[
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
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: canConfirm ? () {
            widget.routine.breakFor(minutes: breakDuration);
            Navigator.of(context).pop();
          } : null,
          child: const Text('Start Break'),
        ),
      ],
    );
  }
}
