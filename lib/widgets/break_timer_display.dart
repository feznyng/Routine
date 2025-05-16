import 'package:flutter/material.dart';
import 'dart:async';
import '../models/routine.dart';

class BreakTimerDisplay extends StatefulWidget {
  final Routine routine;
  final VoidCallback onEndBreak;

  const BreakTimerDisplay({
    super.key,
    required this.routine,
    required this.onEndBreak,
  });

  @override
  State<BreakTimerDisplay> createState() => _BreakTimerDisplayState();
}

class _BreakTimerDisplayState extends State<BreakTimerDisplay> {
  Timer? _breakTimer;
  String _remainingBreakTime = "";
  bool _timerInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Delay timer initialization slightly to ensure all data is loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && widget.routine.isPaused && widget.routine.pausedUntil != null) {
        _updateRemainingBreakTime();
        _startBreakTimer();
        _timerInitialized = true;
      }
    });
  }
  
  @override
  void didUpdateWidget(BreakTimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Always check break status when widget updates
    final wasPaused = oldWidget.routine.isPaused;
    final isPaused = widget.routine.isPaused;
    final pausedUntilChanged = oldWidget.routine.pausedUntil != widget.routine.pausedUntil;
    
    // If pause status or pausedUntil time changed, update timer
    if (wasPaused != isPaused || pausedUntilChanged) {      
      if (isPaused && widget.routine.pausedUntil != null) {
        _updateRemainingBreakTime();
        _startBreakTimer();
        _timerInitialized = true;
      } else {
        _cancelBreakTimer();
        setState(() {
          _remainingBreakTime = "";
        });
        _timerInitialized = false;
      }
    } else if (isPaused && widget.routine.pausedUntil != null && !_timerInitialized) {
      // Catch cases where the widget might have been rebuilt without status change
      _updateRemainingBreakTime();
      _startBreakTimer();
      _timerInitialized = true;
    }
  }
  
  @override
  void dispose() {
    _cancelBreakTimer();
    super.dispose();
  }

  void _startBreakTimer() {
    // Cancel existing timer if any
    _cancelBreakTimer();
    
    // Create a new timer that updates every second
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingBreakTime();
    });
  }
  
  void _cancelBreakTimer() {
    _breakTimer?.cancel();
    _breakTimer = null;
  }

  void _updateRemainingBreakTime() {
    // Skip update if widget is no longer mounted
    if (!mounted) return;
    
    if (widget.routine.pausedUntil == null) {
      setState(() {
        _remainingBreakTime = "";
      });
      return;
    }

    final now = DateTime.now();
    final pausedUntil = widget.routine.pausedUntil!;
    
    if (now.isAfter(pausedUntil)) {
      setState(() {
        _remainingBreakTime = "(00:00)";
      });
      _cancelBreakTimer();
      _timerInitialized = false;
      return;
    }
    
    final remaining = pausedUntil.difference(now);
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    
    // Only update if the time has changed to reduce unnecessary setState calls
    final newTimeString = "($minutes:$seconds)";
    if (_remainingBreakTime != newTimeString) {
      setState(() {
        _remainingBreakTime = newTimeString;
      });
    }
  }

  void _showEndBreakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Break'),
        content: const Text('Are you sure you want to end your break?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onEndBreak();
              Navigator.of(context).pop();
            },
            child: const Text('End Break'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force timer initialization if needed
    if (!_timerInitialized) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateRemainingBreakTime();
          _startBreakTimer();
          _timerInitialized = true;
        }
      });
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _remainingBreakTime.isEmpty ? "" : _remainingBreakTime,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: () => _showEndBreakDialog(context),
          icon: const Icon(Icons.timer_off),
          label: const Text('End Break'),
        ),
      ],
    );
  }
}
