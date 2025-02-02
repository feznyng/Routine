import 'package:flutter/material.dart';
import '../routine.dart';
import 'routine_page.dart';
import '../manager.dart';

class RoutineList extends StatefulWidget {
  const RoutineList({super.key});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> {
  final Manager _manager = Manager();
  late List<Routine> _routines;

  @override
  void initState() {
    super.initState();
    _routines = _manager.routines;
  }

  void _updateRoutines() {
    setState(() {
      _routines = _manager.routines;
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
    final List<String> details = [];
    
    // Add time information
    if (routine.startTime == -1 && routine.endTime == -1) {
      details.add('All day');
    } else {
      final startTimeOfDay = TimeOfDay(hour: routine.startHour, minute: routine.startMinute);
      final endTimeOfDay = TimeOfDay(hour: routine.endHour, minute: routine.endMinute);
      details.add('${startTimeOfDay.format(context)} - ${endTimeOfDay.format(context)}');
    }

    // Add conditions count
    if (routine.conditions.isNotEmpty) {
      details.add('${routine.conditions.length} conditions');
    }

    return Text(details.join(' • '));
  }

  void _showRoutinePage(BuildContext context, Routine? routine) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RoutinePage(
          routine: routine ?? _manager.tempRoutine,
          onSave: (updatedRoutine) {
            if (routine == null) {
              _manager.addRoutine(updatedRoutine);
            } else {
              _manager.updateRoutine(updatedRoutine);
            }
            _updateRoutines();
            Navigator.of(context).pop();
          },
          onDelete: routine != null ? () {
            _manager.removeRoutine(routine.id);
            _updateRoutines();
            Navigator.of(context).pop();
          } : null,
        ),
      ),
    );
  }
}
