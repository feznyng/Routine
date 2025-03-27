import 'dart:async';
import 'dart:io';
import 'package:Routine/services/desktop_service.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import '../models/routine.dart';
import 'routine_page.dart';
import 'routine_card.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({super.key});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> {
  late List<Routine> _routines;
  late StreamSubscription<List<Routine>> _routineSubscription;
  bool _activeRoutinesExpanded = true;
  bool _inactiveRoutinesExpanded = true;
  bool _snoozedRoutinesExpanded = true;
  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];

  @override
  void initState() {
    super.initState();
    _routines = [];
   
    _routineSubscription = Routine.watchAll().listen((routines) {
      if (mounted) {
        setState(() {
          _routines = routines;
        });
    
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          for (final task in _scheduledTasks) {
            task.cancel();
          }

          final desktopService = DesktopService();
          final evaluationTimes = desktopService.getEvaluationTimes(routines);
          for (final Schedule time in evaluationTimes) {
            ScheduledTask task = cron.schedule(time, () async {
              setState(() {
                _routines = routines;
              });
            });
            _scheduledTasks.add(task);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _routineSubscription.cancel();
    super.dispose();
  }

  // Calculate when a routine will be active next
  DateTime _getNextActiveTime(Routine routine) {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday - 1; // 0-based day of week (0 = Monday)
    final currentTimeMinutes = now.hour * 60 + now.minute;
    
    // If routine is all day, we only care about the day
    if (routine.allDay) {
      // Check if routine is active today
      if (routine.days[currentDayOfWeek]) {
        // If it's today, return current time
        return now;
      }
      
      // Find the next day when the routine will be active
      for (int i = 1; i <= 7; i++) {
        final nextDayIndex = (currentDayOfWeek + i) % 7;
        if (routine.days[nextDayIndex]) {
          // Return the start of that day
          return now.add(Duration(days: i)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
        }
      }
    } else {
      // Routine has specific start and end times
      final startTime = routine.startTime;
      final endTime = routine.endTime;
      
      // Check if routine is active today
      if (routine.days[currentDayOfWeek]) {
        // If current time is before start time, routine will be active later today
        if (currentTimeMinutes < startTime) {
          return now.copyWith(
            hour: routine.startHour,
            minute: routine.startMinute,
            second: 0,
            millisecond: 0
          );
        }
        
        // If routine spans midnight and we're after start time, it's active now
        if (endTime < startTime && currentTimeMinutes >= startTime) {
          return now;
        }
        
        // If we're between start and end time, routine is active now
        if (currentTimeMinutes >= startTime && currentTimeMinutes < endTime) {
          return now;
        }
      }
      
      // Find the next day when the routine will be active
      for (int i = 1; i <= 7; i++) {
        final nextDayIndex = (currentDayOfWeek + i) % 7;
        if (routine.days[nextDayIndex]) {
          // Return the start time on that day
          return now.add(Duration(days: i)).copyWith(
            hour: routine.startHour,
            minute: routine.startMinute,
            second: 0,
            millisecond: 0
          );
        }
      }
    }
    
    // If no active days found (shouldn't happen if routine is valid)
    return DateTime(9999); // Far future date
  }
  
  @override
  Widget build(BuildContext context) {
    // Sort all routines by next active time
    final sortedRoutines = List<Routine>.from(_routines);
    sortedRoutines.sort((a, b) {
      // Handle snoozed routines - sort by when they'll be unsnoozed
      if (a.isSnoozed && b.isSnoozed) {
        return a.snoozedUntil!.compareTo(b.snoozedUntil!);
      }
      if (a.isSnoozed) return 1; // Snoozed routines come after active ones
      if (b.isSnoozed) return -1;
      
      // Calculate next active time for both routines
      final aNextActive = _getNextActiveTime(a);
      final bNextActive = _getNextActiveTime(b);
      
      return aNextActive.compareTo(bNextActive);
    });
    
    // Split sorted routines into active, inactive, and snoozed
    final snoozedRoutines = sortedRoutines.where((routine) => routine.isSnoozed).toList();
    final activeRoutines = sortedRoutines.where((routine) => routine.isActive && !routine.isSnoozed).toList();
    final inactiveRoutines = sortedRoutines.where((routine) => !routine.isActive && !routine.isSnoozed).toList();
    
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
          // Active routines section
          if (activeRoutines.isNotEmpty) ...[  
            _buildSectionHeader(
              context, 
              'Current', 
              _activeRoutinesExpanded, 
              () => setState(() => _activeRoutinesExpanded = !_activeRoutinesExpanded)
            ),
            if (_activeRoutinesExpanded)
              ...activeRoutines.map((routine) => RoutineCard(
                routine: routine,
                onRoutineUpdated: () => setState(() {}),
              )),
          ],
          
          // Add padding between sections
          const SizedBox(height: 24),
          
          // Inactive routines section
          if (inactiveRoutines.isNotEmpty) ...[
            _buildSectionHeader(
              context, 
              'Upcoming', 
              _inactiveRoutinesExpanded, 
              () => setState(() => _inactiveRoutinesExpanded = !_inactiveRoutinesExpanded)
            ),
            if (_inactiveRoutinesExpanded)
              ...inactiveRoutines.map((routine) => RoutineCard(
                routine: routine,
                onRoutineUpdated: () => setState(() {}),
              )),
          ],

          
          // Snoozed routines section
          if (snoozedRoutines.isNotEmpty) ...[  
            _buildSectionHeader(
              context, 
              'Snoozed', 
              _snoozedRoutinesExpanded, 
              () => setState(() => _snoozedRoutinesExpanded = !_snoozedRoutinesExpanded)
            ),
            if (_snoozedRoutinesExpanded)
              ...snoozedRoutines.map((routine) => RoutineCard(
                routine: routine,
                onRoutineUpdated: () => setState(() {}),
              )),
          ],

          // Add padding between sections
          const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoutinePage(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isExpanded, VoidCallback onToggle) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$title',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }









  void _showRoutinePage(BuildContext context, Routine? routine) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RoutinePage(
          routine: routine ?? Routine(),
          onSave: (updatedRoutine) {
            Navigator.of(context).pop();
          },
          onDelete: routine != null ? () {
            Navigator.of(context).pop();
          } : null,
        ),
      ),
    );
  }
  

  

}
