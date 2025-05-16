import 'package:flutter/material.dart';
import '../models/routine.dart';
import 'routine_page.dart';
import 'break_dialog.dart';
import 'routine_conditions_list.dart';
import 'break_timer_display.dart';

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

  @override
  Widget build(BuildContext context) {    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showRoutinePage(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.routine.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _buildTimeText(context),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.routine.isSnoozed && widget.routine.snoozedUntil != null) ...[  
                    const Icon(Icons.snooze, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatSnoozeDate(widget.routine.snoozedUntil!),
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                  if (widget.routine.isActive) ...[  
                    const SizedBox(width: 8),
                    _buildBreakButton(context),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _buildBlockedChips(),
              RoutineConditionsList(
                routine: widget.routine,
                onRoutineUpdated: widget.onRoutineUpdated,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTimeText(BuildContext context) {
    // Add time information
    if (widget.routine.startTime == -1 && widget.routine.endTime == -1) {
      return 'All day';
    } else {
      final startTimeOfDay = TimeOfDay(hour: widget.routine.startHour, minute: widget.routine.startMinute);
      final endTimeOfDay = TimeOfDay(hour: widget.routine.endHour, minute: widget.routine.endMinute);
      return '${startTimeOfDay.format(context)} - ${endTimeOfDay.format(context)}';
    }
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
    final suffix = widget.routine.isActive && !isUnlimited && widget.routine.maxBreaks != 0 ? ' left' : '';
    
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
          padding: const EdgeInsets.only(right: 4),
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



  Widget _buildBreakButton(BuildContext context) {
    if (widget.routine.isPaused && widget.routine.pausedUntil != null) {
      return BreakTimerDisplay(
        routine: widget.routine,
        onEndBreak: () {
          widget.routine.endBreak();
          if (widget.onRoutineUpdated != null) {
            widget.onRoutineUpdated!();
          }
        },
      );
    }

    final canBreak = widget.routine.canBreak;
    return TextButton.icon(
      onPressed: canBreak ? () => _showBreakDialog(context) : null,
      icon: const Icon(Icons.coffee),
      label: const Text('Break'),
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
