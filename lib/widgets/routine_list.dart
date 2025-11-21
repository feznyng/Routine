import 'dart:async';
import 'package:Routine/constants.dart';
import 'package:Routine/util.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/sync_service.dart';
import '../services/strict_mode_service.dart';
import '../services/auth_service.dart';
import '../pages/routine_page.dart';
import 'routine_card.dart';
import 'common/emergency_mode_banner.dart';
import 'common/signed_out_banner.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({super.key});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> with WidgetsBindingObserver {
  late List<Routine> _routines;
  late StreamSubscription<List<Routine>> _routineSubscription;
  late StreamSubscription<bool> _syncingSubscription;
  bool _isSyncing = false;
  bool _activeRoutinesExpanded = true;
  bool _inactiveRoutinesExpanded = true;
  bool _completedRoutinesExpanded = true;
  bool _showSignedOutBanner = false;
  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];
  final _syncService = SyncService();
  final _strictModeService = StrictModeService.instance;
  final _authService = AuthService();
  late final StreamSubscription authServiceSubscription;

  @override
  void initState() {
    super.initState();
    _routines = [];
    WidgetsBinding.instance.addObserver(this);
    _checkAuthStatus();
    authServiceSubscription = _authService.authStateChange.listen((data) {
      if (mounted) {
        _checkAuthStatus();
      }
    });
   
    _routineSubscription = Routine.watchAll().listen((routines) {
      if (mounted) {
        setState(() {
          _routines = routines;
        });
    
        Util.scheduleEvaluationTimes(routines, _scheduledTasks, () async {
            if (mounted) {
              setState(() {
                _routines = routines;
              });
            }
        });
      }
    });

    _syncingSubscription = _syncService.isSyncing.listen((value) {
      if (mounted) {
        setState(() {
          _isSyncing = value;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routineSubscription.cancel();
    _syncingSubscription.cancel();
    authServiceSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuthStatus();
      setState(() {
        _routines = _routines;
      });
    }
  }
  
  Future<void> _checkAuthStatus() async {
    if ((await _authService.wasSignedOut) == false) {
      setState(() {
        _showSignedOutBanner = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedRoutines = List<Routine>.from(_routines);
    sortedRoutines.sort((a, b) => a.nextActiveTime.compareTo(b.nextActiveTime));
    
    final completedRoutines = sortedRoutines.where((routine) => routine.canCompleteConditions && routine.areConditionsMet).toList();
    final activeRoutines = sortedRoutines.where((routine) => routine.isActive && !completedRoutines.contains(routine)).toList();
    final inactiveRoutines = sortedRoutines.where((routine) => !routine.isActive && !completedRoutines.contains(routine)).toList();
       
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _routines.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                onRefresh: () async {
                  _syncService.queueSync('manual_sync');
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (_strictModeService.emergencyMode)
                      const EmergencyModeBanner(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Opacity(
                            opacity: _isSyncing ? 1 : 0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: const CircularProgressIndicator(strokeWidth: 1.5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Syncing…',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showSignedOutBanner)
                      SignedOutBanner(
                        onDismiss: () {
                          _authService.clearSignedInFlag();
                          setState(() {
                            _showSignedOutBanner = false;
                          });
                        },
                      ),
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
                    if (activeRoutines.isNotEmpty && completedRoutines.isNotEmpty && (_activeRoutinesExpanded || _completedRoutinesExpanded))
                      const SizedBox(height: 24),
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
                    if (completedRoutines.isNotEmpty && inactiveRoutines.isNotEmpty && (_completedRoutinesExpanded || _inactiveRoutinesExpanded))
                      const SizedBox(height: 24),
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
                    ]
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
