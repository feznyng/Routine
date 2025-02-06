import 'package:flutter/material.dart';
import '../routine.dart';
import 'routine_page.dart';
import 'break_dialog.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({super.key});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> {
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
              trailing: routine.isActive ? _buildBreakButton(context, routine) : null,
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
    showDialog(
      context: context,
      builder: (context) => BreakDialog(routine: routine),
      barrierDismissible: false,
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
