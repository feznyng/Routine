import 'dart:async';
import 'package:Routine/constants.dart';
import 'package:Routine/util.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/sync_service.dart';
import '../services/strict_mode_service.dart';
import 'routine_page.dart';
import 'routine_card.dart';
import 'common/emergency_mode_banner.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({super.key});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> with WidgetsBindingObserver {
  late List<Routine> _routines;
  late StreamSubscription<List<Routine>> _routineSubscription;
  bool _isLoading = false;
  bool _activeRoutinesExpanded = true;
  bool _inactiveRoutinesExpanded = true;
  bool _snoozedRoutinesExpanded = true;
  bool _completedRoutinesExpanded = true;
  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];
  final _syncService = SyncService();
  final _strictModeService = StrictModeService.instance;

  @override
  void initState() {
    super.initState();
    print("UI: INIT LIST");
    _routines = [];
    _isLoading = true;
    WidgetsBinding.instance.addObserver(this);
   
    _routineSubscription = Routine.watchAll().listen((routines) {
      if (mounted) {
        print("UI: ROUTINES UPDATED");
        setState(() {
          _routines = routines;
          _isLoading = false;
        });
    
        for (final task in _scheduledTasks) {
          task.cancel();
        }

        final evaluationTimes = Util.getEvaluationTimes(routines);
        for (final Schedule time in evaluationTimes) {
          ScheduledTask task = cron.schedule(time, () async {
            setState(() {
              _routines = routines;
            });
          });
          _scheduledTasks.add(task);
        }
      
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routineSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh the list when app is resumed
      setState(() {
        _routines = _routines;
      });
    }
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
    print("UI: BUILDING LIST");

    final stopWatch = Stopwatch();

    // Sort all routines by next active time, except active ones which are sorted by start time
    final sortedRoutines = List<Routine>.from(_routines);
    sortedRoutines.sort((a, b) {
      // Handle snoozed routines - sort by when they'll be unsnoozed
      if (a.isSnoozed && b.isSnoozed) {
        return a.snoozedUntil!.compareTo(b.snoozedUntil!);
      }
      if (a.isSnoozed) return 1; // Snoozed routines come after active ones
      if (b.isSnoozed) return -1;
      
      // If both routines are active, sort by start time (most recent first)
      if (a.isActive && b.isActive && !a.areConditionsMet && !b.areConditionsMet) {
        final aStartTime = a.startTime;
        final bStartTime = b.startTime;
        // For routines that started today, compare their start times
        // Later start times should come first (reverse order)
        return bStartTime.compareTo(aStartTime);
      }
      
      // Otherwise, sort by next active time
      final aNextActive = _getNextActiveTime(a);
      final bNextActive = _getNextActiveTime(b);
      return aNextActive.compareTo(bNextActive);
    });
    
    // Split sorted routines into completed, active, inactive, and snoozed
    final snoozedRoutines = sortedRoutines.where((routine) => routine.isSnoozed).toList();
    final completedRoutines = sortedRoutines.where((routine) => !routine.isSnoozed && routine.isActive && routine.areConditionsMet).toList();
    final activeRoutines = sortedRoutines.where((routine) => routine.isActive && !routine.isSnoozed && !routine.areConditionsMet).toList();
    final inactiveRoutines = sortedRoutines.where((routine) => !routine.isActive && !routine.isSnoozed).toList();
   
    print("UI: FINISHED BUILDING LIST in ${stopWatch.elapsed}ns");
    
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _routines.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                onRefresh: () async {
                  // Trigger a full sync
                  setState(() {
                    _isLoading = true;
                  });
                  await _syncService.sync(full: true);
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Emergency mode banner
                    if (_strictModeService.emergencyMode)
                      const EmergencyModeBanner(),
                    // Active routines section
                    if (activeRoutines.isNotEmpty) ...[  
                      _buildSectionHeader(
                        context, 
                        'Active', 
                        _activeRoutinesExpanded, 
                        () => setState(() => _activeRoutinesExpanded = !_activeRoutinesExpanded)
                      ),
                      if (_activeRoutinesExpanded)
                        ...activeRoutines.map((routine) => RoutineCard(
                          routine: routine,
                          onRoutineUpdated: () => setState(() {}),
                        )),
                    ],

                    // Add padding between sections only if one is expanded
                    if (_activeRoutinesExpanded || _completedRoutinesExpanded)
                      const SizedBox(height: 24),

                    // Completed routines section
                    if (completedRoutines.isNotEmpty) ...[  
                      _buildSectionHeader(
                        context, 
                        'Completed', 
                        _completedRoutinesExpanded, 
                        () => setState(() => _completedRoutinesExpanded = !_completedRoutinesExpanded)
                      ),
                      if (_completedRoutinesExpanded)
                        ...completedRoutines.map((routine) => RoutineCard(
                          routine: routine,
                          onRoutineUpdated: () => setState(() {}),
                        )),
                    ],

                    // Add padding between sections only if one is expanded
                    if (_completedRoutinesExpanded || _inactiveRoutinesExpanded)
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isExpanded ? 12 : 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
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
  
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.schedule_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'No routines yet',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the + button to create your first routine',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showRoutinePage(BuildContext context, Routine? routine) {
    // If creating a new routine (routine is null) and we already have 20 or more routines,
    // show a limit reached dialog
    if (routine == null && _routines.length >= kMaxRoutines) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Routine Limit Reached'),
          content: const Text('You have reached the maximum limit of $kMaxRoutines routines. Please delete some routines before creating new ones.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

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
