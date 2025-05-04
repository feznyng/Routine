import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/routine.dart';
import '../models/condition.dart';
import 'routine_page.dart';
import 'break_dialog.dart';
import 'qr_scanner_page.dart';

class RoutineCard extends StatefulWidget {
  final Routine routine;
  final VoidCallback? onRoutineUpdated;

  const RoutineCard({
    super.key,
    required this.routine,
    this.onRoutineUpdated,
  });

  @override
  State<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  Timer? _breakTimer;
  String _remainingBreakTime = "";
  bool _timerInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Delay timer initialization slightly to ensure all data is loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && widget.routine.isPaused && widget.routine.pausedUntil != null) {
        print("Initializing timer in initState for ${widget.routine.name}");
        _updateRemainingBreakTime();
        _startBreakTimer();
        _timerInitialized = true;
      }
    });
  }
  
  @override
  void didUpdateWidget(RoutineCard oldWidget) {
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
      print("Reinitializing timer for ${widget.routine.name} that was missed");
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

  @override
  Widget build(BuildContext context) {
    // Check if we need to initialize the timer on build
    if (widget.routine.isPaused && widget.routine.pausedUntil != null && !_timerInitialized) {
      print("Initializing timer in build for ${widget.routine.name}");
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateRemainingBreakTime();
          _startBreakTimer();
          _timerInitialized = true;
        }
      });
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(widget.routine.name),
                ),
                if (widget.routine.isSnoozed && widget.routine.snoozedUntil != null) ...[  
                  const Icon(Icons.snooze, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatSnoozeDate(widget.routine.snoozedUntil!),
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ],
            ),
            subtitle: _buildRoutineSubtitle(context),
            isThreeLine: true,
            trailing: widget.routine.isActive ? _buildBreakButton(context) : null,
            onTap: () {
              _showRoutinePage(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSubtitle(BuildContext context) {
    String timeText;
    
    // Add time information
    if (widget.routine.startTime == -1 && widget.routine.endTime == -1) {
      timeText = 'All day';
    } else {
      final startTimeOfDay = TimeOfDay(hour: widget.routine.startHour, minute: widget.routine.startMinute);
      final endTimeOfDay = TimeOfDay(hour: widget.routine.endHour, minute: widget.routine.endMinute);
      timeText = '${startTimeOfDay.format(context)} - ${endTimeOfDay.format(context)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(timeText),
        const SizedBox(height: 4),
        _buildBlockedChips(),
        if (widget.routine.isActive && widget.routine.conditions.isNotEmpty) ...[  
          const SizedBox(height: 8),
          _buildConditionsList(context),
        ],
      ],
    );
  }

  // Helper method to create consistently styled chips
  Widget _buildStyledChip(String text) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildBlockedChips() {
    final group = widget.routine.getGroup();
    List<String> chipTexts = [];
    
    // Collect all chip texts first
    if (group == null) {
      // If there's no block group configured for the current device, show a 'None' chip
      chipTexts.add('None');
    } else if (group.name != null) {
      // If the group has a name, just show that
      chipTexts.add(group.name!);
    } else {
      // Otherwise show details about what's being blocked/allowed
      final apps = group.apps;
      final sites = group.sites;
      final categories = group.categories;
      final isAllowlist = group.allow;
      
      // Add block/allow chip
      chipTexts.add(isAllowlist ? 'Allow' : 'Block');
      
      // Add app chip if there are apps or if it's an allowlist with no apps
      if (apps.isNotEmpty || (isAllowlist && apps.isEmpty)) {
        chipTexts.add(apps.isEmpty && isAllowlist
            ? 'No apps'
            : '${apps.length} ${apps.length == 1 ? 'app' : 'apps'}');
      }
      
      // Add site chip if there are sites or if it's an allowlist with no sites
      if (sites.isNotEmpty || (isAllowlist && sites.isEmpty)) {
        chipTexts.add(sites.isEmpty && isAllowlist
            ? 'No sites'
            : '${sites.length} ${sites.length == 1 ? 'site' : 'sites'}');
      }
      
      // Add category chip if there are categories
      if (categories.isNotEmpty) {
        chipTexts.add('${categories.length} ${categories.length == 1 ? 'category' : 'categories'}');
      }
    }
    
    // Add strict mode chip if enabled
    if (widget.routine.strictMode) {
      chipTexts.add('Strict');
    }
        
    // Always add breaks chip
    final breaksLeftText = widget.routine.breaksLeftText;
    final numBreaksLeft = widget.routine.numBreaksLeft;
    final isUnlimited = breaksLeftText == "Unlimited";
    final breakWord = numBreaksLeft == 1 ? 'break' : 'breaks';
    final suffix = widget.routine.isActive && !isUnlimited ? ' left' : '';
    
    chipTexts.add('$breaksLeftText ${isUnlimited ? "breaks" : "$breakWord$suffix"}');

    // Transform all texts to styled chips
    final chips = chipTexts.map((text) {
      // Special styling for strict mode chip
      if (text == 'Strict') {
        return Chip(
          label: const Text(
            'Strict',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }
      // No special styling for snoozed status anymore
      return _buildStyledChip(text);
    }).toList();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
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

  Widget _buildBreakButton(BuildContext context) {
    if (widget.routine.isPaused && widget.routine.pausedUntil != null) {
      // Force timer initialization if needed when building the break button
      if (!_timerInitialized) {
        print("Initializing timer in _buildBreakButton for ${widget.routine.name}");
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
            _remainingBreakTime.isEmpty ? "(calculating...)" : _remainingBreakTime,
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

    final canBreak = widget.routine.canBreak;
    return TextButton.icon(
      onPressed: canBreak ? () => _showBreakDialog(context) : null,
      icon: const Icon(Icons.coffee),
      label: const Text('Break'),
    );
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
              widget.routine.endBreak();
              if (widget.onRoutineUpdated != null) {
                widget.onRoutineUpdated!();
              }
              Navigator.of(context).pop();
            },
            child: const Text('End Break'),
          ),
        ],
      ),
    );
  }

  void _showBreakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BreakDialog(routine: widget.routine),
      barrierDismissible: false,
    );
  }

  void _showRoutinePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RoutinePage(
          routine: widget.routine,
          onSave: (updatedRoutine) {
            if (widget.onRoutineUpdated != null) {
              widget.onRoutineUpdated!();
            }
            Navigator.of(context).pop();
          },
          onDelete: () {
            if (widget.onRoutineUpdated != null) {
              widget.onRoutineUpdated!();
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
  
  Widget _buildConditionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ...widget.routine.conditions.map((condition) => _buildConditionItem(context, condition)),
      ],
    );
  }
  
  Widget _buildConditionItem(BuildContext context, Condition condition) {
    final isMet = widget.routine.isConditionMet(condition);
    
    // Get the appropriate icon based on condition type
    IconData getConditionIcon() {
      switch (condition.type) {
        case ConditionType.location:
          return Icons.location_on;
        case ConditionType.nfc:
          return Icons.nfc;
        case ConditionType.qr:
          return Icons.qr_code;
        case ConditionType.health:
          return Icons.favorite;
        case ConditionType.todo:
          return Icons.assignment_turned_in;
      }
    }
    
    String getConditionDescription() {
      if (condition.name != null && condition.name!.isNotEmpty) {
        return condition.name! + (condition.proximity != null ? ' (${condition.proximity!.toInt()} m)' : '');
      }
      
      switch (condition.type) {
        case ConditionType.location:
          if (condition.latitude != null && condition.longitude != null) {
            return 'Location';
          }
          return 'Location: Not set';
        case ConditionType.nfc:
          return 'NFC Tag';
        case ConditionType.qr:
          return 'QR Code';
        case ConditionType.health:
          return 'Health: ${condition.activityType ?? 'Not set'}';
        case ConditionType.todo:
          return condition.name ?? 'To-do item';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _handleConditionTap(context, condition),
        child: Row(
          children: [
            Icon(getConditionIcon(), size: 16),
            const SizedBox(width: 8),
            Checkbox(
              value: isMet,
              onChanged: (_) => _handleConditionTap(context, condition),
            ),
            Expanded(
              child: Text(
                getConditionDescription(),
                style: TextStyle(
                  decoration: isMet ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleConditionTap(BuildContext context, Condition condition) {
    final isMet = widget.routine.isConditionMet(condition);
    
    // If the condition is already completed, show a confirmation dialog
    if (isMet) {
      _showUncompleteConfirmationDialog(context, condition);
      return;
    }
    
    // Handle different condition types
    switch (condition.type) {
      case ConditionType.todo:
        // Todo conditions can be completed directly
        widget.routine.completeCondition(condition);
        if (widget.onRoutineUpdated != null) {
          widget.onRoutineUpdated!();
        }
        break;
        
      case ConditionType.location:
        // Check current location against condition location
        _handleLocationCondition(context, condition);
        break;
        
      case ConditionType.qr:
        // Open QR code scanner for QR conditions
        _handleQrCondition(context, condition);
        break;
        
      case ConditionType.nfc:
        // Show a placeholder dialog for NFC conditions
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('NFC Tag Condition'),
            content: const Text('Scan an NFC tag to complete this condition.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        break;
        
      default:
        // Show a placeholder dialog for other condition types
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Complete ${condition.type.toString().split('.').last} Condition'),
            content: const Text('This condition type is not yet implemented.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
    }
  }
  
  void _handleQrCondition(BuildContext context, Condition condition) {
    // Navigate to the QR scanner page
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => QrScannerPage(
          onCodeScanned: (scannedData) {
            // Compare scanned data with condition data
            if (scannedData == condition.data) {
              // QR code matches, complete the condition
              widget.routine.completeCondition(condition);
              if (widget.onRoutineUpdated != null) {
                widget.onRoutineUpdated!();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR code verified! Condition completed.')),
              );
            } else {
              // QR code doesn't match
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid QR code. Please try again with the correct code.')),
              );
            }
          },
        ),
      ),
    );
  }
  
  void _handleLocationCondition(BuildContext context, Condition condition) async {
    if (condition.latitude == null || condition.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not set for this condition')),
      );
      return;
    }
    
    try {
      // First, check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        // If still denied after request, show error
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Cannot check location condition.')),
          );
          return;
        }
        
        // Add a small delay after permission is granted to allow the system to update
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
        );
        return;
      }
      
      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        condition.latitude!,
        condition.longitude!,
      );
      
      final proximity = condition.proximity ?? 100; // Default to 100 meters if not set
      
      if (distance <= proximity) {
        // User is within the proximity radius
        widget.routine.completeCondition(condition);
        if (widget.onRoutineUpdated != null) {
          widget.onRoutineUpdated!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location condition completed!')),
        );
      } else {
        // User is not within the proximity radius
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${distance.toInt()} meters away from the target location. Please move within ${proximity.toInt()} meter${proximity == 1.0 ? '' : 's'}.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking location: $e')),
      );
    }
  }
  
  void _showUncompleteConfirmationDialog(BuildContext context, Condition condition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uncomplete Condition'),
        content: const Text('Are you sure you want to mark this condition as not completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.routine.completeCondition(condition, complete: false);
              if (widget.onRoutineUpdated != null) {
                widget.onRoutineUpdated!();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Uncomplete'),
          ),
        ],
      ),
    );
  }
  
  String _formatSnoozeDate(DateTime dateTime) {
    // Convert to local time if in UTC
    if (dateTime.isUtc) {
      dateTime = dateTime.toLocal();
    }

    // Convert to local time if in UTC
    if (dateTime.isUtc) {
      dateTime = dateTime.toLocal();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (dateToCheck.isAtSameMomentAs(today)) {
      dateStr = 'Today';
    } else if (dateToCheck.isAtSameMomentAs(tomorrow)) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.month}/${dateTime.day}';
    }
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$dateStr $hour:$minute $period';
  }
}
