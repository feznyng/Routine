import 'package:flutter/material.dart';
import '../../models/routine.dart';
import 'delay_friction_display.dart';
import 'pomodoro_friction_display.dart';
import 'intention_friction_display.dart';
import 'code_friction_display.dart';
import 'qr_friction_display.dart';
import 'nfc_friction_display.dart';

/// Main friction display widget that routes to specific friction type widgets
class FrictionDisplay extends StatelessWidget {
  final Routine routine;
  final int? remainingDelay;
  final int? remainingPomodoroSeconds;
  final String? generatedCode;
  final TextEditingController codeController;
  final bool canConfirm;
  final String? scanFeedback;
  final ValueChanged<bool> onCanConfirmChanged;
  final ValueChanged<String?> onScanFeedbackChanged;

  const FrictionDisplay({
    super.key,
    required this.routine,
    required this.remainingDelay,
    required this.remainingPomodoroSeconds,
    required this.generatedCode,
    required this.codeController,
    required this.canConfirm,
    required this.scanFeedback,
    required this.onCanConfirmChanged,
    required this.onScanFeedbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (routine.friction) {
      case 'delay':
        return DelayFrictionDisplay(
          remainingDelay: remainingDelay,
        );
      case 'pomodoro':
        return PomodoroFrictionDisplay(
          routine: routine,
          remainingPomodoroSeconds: remainingPomodoroSeconds,
        );
      case 'intention':
        return IntentionFrictionDisplay(
          onCanConfirmChanged: onCanConfirmChanged,
        );
      case 'code':
        return CodeFrictionDisplay(
          generatedCode: generatedCode,
          codeController: codeController,
          onCanConfirmChanged: onCanConfirmChanged,
        );
      case 'qr':
        return QrFrictionDisplay(
          routine: routine,
          canConfirm: canConfirm,
          scanFeedback: scanFeedback,
          onCanConfirmChanged: onCanConfirmChanged,
          onScanFeedbackChanged: onScanFeedbackChanged,
        );
      case 'nfc':
        return NfcFrictionDisplay(
          routine: routine,
          canConfirm: canConfirm,
          scanFeedback: scanFeedback,
          onCanConfirmChanged: onCanConfirmChanged,
          onScanFeedbackChanged: onScanFeedbackChanged,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
