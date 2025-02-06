import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../routine.dart';
import 'routine_page.dart';
import 'package:flutter/services.dart';
import '../database.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({super.key});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> {
  final _codeController = TextEditingController();
  Timer? _delayTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }
  late List<Routine> _routines;

  @override
  void initState() {
    super.initState();
    _routines = [];
   
    Routine.watchAll().listen((routines) {
      setState(() {
        _routines = routines;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(routine.name),
              subtitle: _buildRoutineSubtitle(context, routine),
              isThreeLine: true,
              trailing: _buildBreakButton(context, routine),
              onTap: () {
                _showRoutinePage(context, routine);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoutinePage(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoutineSubtitle(BuildContext context, Routine routine) {
    String timeText;
    
    // Add time information
    if (routine.startTime == -1 && routine.endTime == -1) {
      timeText = 'All day';
    } else {
      final startTimeOfDay = TimeOfDay(hour: routine.startHour, minute: routine.startMinute);
      final endTimeOfDay = TimeOfDay(hour: routine.endHour, minute: routine.endMinute);
      timeText = '${startTimeOfDay.format(context)} - ${endTimeOfDay.format(context)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(timeText),
        const SizedBox(height: 4),
        _buildBlockedChips(routine),
      ],
    );
  }

  Widget _buildBlockedChips(Routine routine) {
    final group = routine.getGroup();
    if (group == null) return const SizedBox.shrink();

    final apps = group.apps;
    final sites = group.sites;
    final isAllowlist = group.allow;
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Chip(
          label: Text(
            isAllowlist ? 'Allow' : 'Block',
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        Chip(
          label: Text(
            apps.isEmpty && isAllowlist
                ? 'No apps'
                : '${apps.length} ${apps.length == 1 ? 'app' : 'apps'}',
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        Chip(
          label: Text(
            sites.isEmpty && isAllowlist
                ? 'No sites'
                : '${sites.length} ${sites.length == 1 ? 'site' : 'sites'}',
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ],
    );
  }

  Widget _buildBreakButton(BuildContext context, Routine routine) {
    if (routine.breakUntil != null) {
      return TextButton.icon(
        onPressed: () => _showEndBreakDialog(context, routine),
        icon: const Icon(Icons.timer),
        label: const Text('End Break'),
      );
    }

    final canBreak = routine.canBreak;
    return TextButton.icon(
      onPressed: canBreak ? () => _showBreakDialog(context, routine) : null,
      icon: const Icon(Icons.coffee),
      label: const Text('Break'),
    );
  }

  void _showEndBreakDialog(BuildContext context, Routine routine) {
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
              routine.endBreak();
              Navigator.of(context).pop();
            },
            child: const Text('End Break'),
          ),
        ],
      ),
    );
  }

  void _showBreakDialog(BuildContext context, Routine routine) {
    int breakDuration = 15;
    bool canConfirm = routine.friction == FrictionType.none;
    int? remainingDelay;
    String? generatedCode;

    if (routine.friction == FrictionType.code) {
      // Generate random 6-character code
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      generatedCode = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Take a Break'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Break Duration'),
              const SizedBox(height: 8),
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
                    enabled: breakDuration < routine.maxBreakDuration,
                  ),
                ],
                emptySelectionAllowed: true,
                selected: const {},
                onSelectionChanged: (Set<String> selected) {
                  setState(() {
                    if (selected.first == 'minus' && breakDuration > 5) {
                      breakDuration = breakDuration - 5;
                    } else if (selected.first == 'plus' && breakDuration < routine.maxBreakDuration) {
                      breakDuration = breakDuration + 5;
                    }
                  });
                },
              ),
              if (routine.friction != FrictionType.none) ...[              
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                if (routine.friction == FrictionType.delay) ...[                
                  Text(remainingDelay == null 
                    ? 'Wait ${routine.frictionLen ?? 30} seconds'
                    : 'Wait $remainingDelay seconds'),
                ] else if (routine.friction == FrictionType.intention) ...[                
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
                ] else if (routine.friction == FrictionType.code) ...[                
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
              onPressed: () {
                _delayTimer?.cancel();
                _codeController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: canConfirm ? () {
                routine.breakFor(minutes: breakDuration);
                _delayTimer?.cancel();
                _codeController.clear();
                Navigator.of(context).pop();
              } : null,
              child: const Text('Start Break'),
            ),
          ],
        ),
      ),
    ).then((_) {
      _delayTimer?.cancel();
      _codeController.clear();
    });

    // Start delay timer if needed
    if (routine.friction == FrictionType.delay) {
      remainingDelay = routine.frictionLen ?? 30;
      _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingDelay! > 0) {
          setState(() => remainingDelay = remainingDelay! - 1);
        } else {
          setState(() => canConfirm = true);
          timer.cancel();
        }
      });
    }
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
