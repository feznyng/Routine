import 'package:flutter/material.dart';
import '../routine.dart';
import '../manager.dart';
import 'routine_dialog.dart';

class RoutineList extends StatelessWidget {
  final List<Routine> routines;
  final Function(Routine) onRoutineUpdated;
  final Function(Routine) onRoutineDeleted;
  final Function() onRoutineCreated;

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
              subtitle: _buildRoutineSubtitle(routine),
              onTap: () => _showRoutineDialog(context, routine),
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

  Widget _buildRoutineSubtitle(Routine routine) {
    final List<String> details = [];
    
    // Add time information
    if (routine.startTime == -1 && routine.endTime == -1) {
      details.add('All day');
    } else {
      final startHour = routine.startHour.toString().padLeft(2, '0');
      final startMinute = routine.startMinute.toString().padLeft(2, '0');
      final endHour = routine.endHour.toString().padLeft(2, '0');
      final endMinute = routine.endMinute.toString().padLeft(2, '0');
      details.add('$startHour:$startMinute - $endHour:$endMinute');
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
            onRoutineCreated();
          } else {
            onRoutineUpdated(updatedRoutine);
          }
        },
        onDelete: routine != null ? () => onRoutineDeleted(routine) : null,
      ),
    );
  }
}
