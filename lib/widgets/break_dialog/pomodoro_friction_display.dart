import 'package:flutter/material.dart';
import '../../models/routine.dart';

/// Pomodoro friction display widget
class PomodoroFrictionDisplay extends StatelessWidget {
  final Routine routine;
  final int? remainingPomodoroSeconds;

  const PomodoroFrictionDisplay({
    super.key,
    required this.routine,
    required this.remainingPomodoroSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final int remainingSeconds = remainingPomodoroSeconds ?? routine.getRemainingPomodoroTime;
    final int minutes = remainingSeconds ~/ 60;
    final int seconds = remainingSeconds % 60;
    
    if (remainingSeconds > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pomodoro',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    height: 170,
                    width: 170,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Progress indicator
                  SizedBox(
                    height: 170,
                    width: 170,
                    child: CircularProgressIndicator(
                      value: routine.frictionLen != null && routine.frictionLen! > 0 ?
                        1 - (remainingSeconds / (routine.frictionLen! * 60)) : 0,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      strokeWidth: 8.0,
                    ),
                  ),
                  // Inner circle with time display
                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
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
                        const SizedBox(height: 4),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
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
  }
}
