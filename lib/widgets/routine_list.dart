import 'package:flutter/material.dart';
import '../routine.dart';
import 'routine_dialog.dart';

class RoutineList extends StatelessWidget {
  final List<Routine> routines;
  final Function(Routine) onRoutineUpdated;
  final Function(Routine) onRoutineDeleted;
  final Function(Routine) onRoutineCreated;

  const RoutineList({
    super.key,
    required this.routines,
    required this.onRoutineUpdated,
    required this.onRoutineDeleted,
    required this.onRoutineCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(routine.name),
              subtitle: _buildRoutineSubtitle(context, routine),
              onTap: () {
                _showRoutineDialog(context, routine);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoutineDialog(context, null),
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

  void _showRoutineDialog(BuildContext context, Routine? routine) {
    showDialog(
      context: context,
      builder: (context) => RoutineDialog(
        routine: routine,
        onSave: (updatedRoutine) {
          if (routine == null) {
            onRoutineCreated(updatedRoutine);
          } else {
            onRoutineUpdated(updatedRoutine);
          }
        },
        onDelete: routine != null ? () => onRoutineDeleted(routine) : null,
      ),
    );
  }
}
