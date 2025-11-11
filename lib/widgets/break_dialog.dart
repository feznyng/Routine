import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/routine.dart';
import 'break_dialog/friction_display.dart';

class BreakDialog extends StatefulWidget {
  final Routine routine;

  const BreakDialog({
    super.key,
    required this.routine,
  });

  @override
  State<BreakDialog> createState() => _BreakDialogState();
}

class _BreakDialogState extends State<BreakDialog> with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  Timer? _delayTimer;
  Timer? _pomodoroTimer;
  late int breakDuration;
  bool canConfirm = false;
  String? _scanFeedback;
  int? remainingDelay;
  int? remainingPomodoroSeconds;
  String? generatedCode;
  DateTime? _delayEndAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    canConfirm = widget.routine.friction == 'none' || 
                (widget.routine.friction == 'pomodoro' && widget.routine.canTakeBreakNowWithPomodoro);

    breakDuration = widget.routine.maxBreakDuration;

    if (widget.routine.friction == 'code') {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();

      final codeLength = widget.routine.frictionLen ?? widget.routine.calculateCodeLength();
      generatedCode = List.generate(codeLength, (index) => chars[random.nextInt(chars.length)]).join();
    } else if (widget.routine.friction == 'delay') {
      remainingDelay = widget.routine.frictionLen ?? 30;
      _delayEndAt = DateTime.now().add(Duration(seconds: remainingDelay!));
      _startDelayTimer();
    } else if (widget.routine.friction == 'pomodoro') {
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
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    _delayTimer?.cancel();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() {
    if (!mounted) return;
    if (!widget.routine.isActive) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      if (widget.routine.friction == 'pomodoro') {
        final remaining = widget.routine.getRemainingPomodoroTime;
        remainingPomodoroSeconds = remaining > 0 ? remaining : 0;
        canConfirm = widget.routine.canTakeBreakNowWithPomodoro;

        if (remainingPomodoroSeconds! > 0) {
          if (_pomodoroTimer == null) _startPomodoroTimer();
        } else {
          _pomodoroTimer?.cancel();
        }
      } else if (widget.routine.friction == 'delay') {
        if (_delayEndAt != null) {
          final now = DateTime.now();
          final diff = _delayEndAt!.difference(now).inSeconds;
          remainingDelay = max(0, diff);
          if (remainingDelay == 0) {
            canConfirm = true;
            _delayTimer?.cancel();
          } else {
            if (_delayTimer == null) _startDelayTimer();
          }
        }
      }
    });
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.coffee,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Take a Break',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          minWidth: 360,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.routine.breaksLeftText} break${widget.routine.numBreaksLeft == 1 ? '' : 's'} remaining',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.routine.friction != 'none') ...[
                FrictionDisplay(
                  routine: widget.routine,
                  remainingDelay: remainingDelay,
                  remainingPomodoroSeconds: remainingPomodoroSeconds,
                  generatedCode: generatedCode,
                  codeController: _codeController,
                  canConfirm: canConfirm,
                  scanFeedback: _scanFeedback,
                  onCanConfirmChanged: (value) => setState(() => canConfirm = value),
                  onScanFeedbackChanged: (value) => setState(() => _scanFeedback = value),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
              ],
              Text(
                'Break Duration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: canConfirm 
                    ? null 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'minus',
                    icon: const Icon(Icons.remove, size: 20),
                    enabled: canConfirm && breakDuration > 5,
                  ),
                  ButtonSegment(
                    value: 'text',
                    label: Text(
                      '$breakDuration min',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: canConfirm 
                          ? null 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: 'plus',
                    icon: const Icon(Icons.add, size: 20),
                    enabled: canConfirm && breakDuration < widget.routine.maxBreakDuration,
                  ),
                ],
                emptySelectionAllowed: true,
                selected: const {},
                onSelectionChanged: canConfirm ? (Set<String> selected) {
                  if (selected.isNotEmpty) {
                    setState(() {
                      if (selected.first == 'minus' && breakDuration > 5) {
                        breakDuration = breakDuration - 5;
                      } else if (selected.first == 'plus' && breakDuration < widget.routine.maxBreakDuration) {
                        breakDuration = breakDuration + 5;
                      }
                    });
                  }
                } : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canConfirm ? () async {
            await widget.routine.breakFor(minutes: breakDuration);
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          } : null,
          child: const Text('Start Break'),
        ),
      ],
    );
  }
}
