import 'package:flutter/material.dart';
import '../routine.dart';
import '../condition.dart';
import 'package:uuid/uuid.dart';

class RoutineDialog extends StatefulWidget {
  final Routine? routine;
  final Function(Routine) onSave;
  final Function()? onDelete;

  const RoutineDialog({
    super.key,
    this.routine,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<RoutineDialog> createState() => _RoutineDialogState();
}

class _RoutineDialogState extends State<RoutineDialog> {
  late TextEditingController _nameController;
  late List<bool> _selectedDays;
  late bool _isAllDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<Condition> _conditions;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.name ?? '');
    _selectedDays = List.filled(7, true); // Default to all days selected
    _isAllDay = widget.routine?.startTime == -1;
    _startTime = widget.routine?.startTime != -1
        ? TimeOfDay(
            hour: widget.routine!.startHour,
            minute: widget.routine!.startMinute,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.routine?.endTime != -1
        ? TimeOfDay(
            hour: widget.routine!.endHour,
            minute: widget.routine!.endMinute,
          )
        : const TimeOfDay(hour: 17, minute: 0);
    _conditions = widget.routine?.conditions ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.routine == null ? 'Create Routine' : 'Edit Routine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Routine Name'),
            ),
            const SizedBox(height: 16),
            _buildDaySelector(),
            const SizedBox(height: 16),
            _buildTimeSection(),
            const SizedBox(height: 16),
            _buildConditionsList(),
          ],
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete!();
            },
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveRoutine,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 4,
      children: [
        for (int i = 0; i < 7; i++)
          FilterChip(
            label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]),
            selected: _selectedDays[i],
            onSelected: (bool selected) {
              setState(() {
                _selectedDays[i] = selected;
              });
            },
          ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('All Day'),
          value: _isAllDay,
          onChanged: (value) {
            setState(() {
              _isAllDay = value;
            });
          },
        ),
        if (!_isAllDay) ...[
          ListTile(
            title: const Text('Start Time'),
            trailing: Text(_startTime.format(context)),
            onTap: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                });
              }
            },
          ),
          ListTile(
            title: const Text('End Time'),
            trailing: Text(_endTime.format(context)),
            onTap: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                });
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildConditionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Conditions'),
        const SizedBox(height: 8),
        if (_conditions.isEmpty)
          const Text('No conditions added', style: TextStyle(fontStyle: FontStyle.italic)),
        ..._conditions.map((condition) => ListTile(
              title: Text(condition.runtimeType.toString()),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _conditions.remove(condition);
                  });
                },
              ),
            )),
        TextButton.icon(
          onPressed: _addCondition,
          icon: const Icon(Icons.add),
          label: const Text('Add Condition'),
        ),
      ],
    );
  }

  void _addCondition() {
    // TODO: Implement condition creation dialog
    // This would show a dialog to select condition type and configure its parameters
  }

  void _saveRoutine() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine name')),
      );
      return;
    }

    final routine = widget.routine ?? Routine(
      id: const Uuid().v4(),
      name: _nameController.text,
    );

    routine.setDays(_selectedDays);
    
    if (_isAllDay) {
      routine.setAllDay();
    } else {
      routine.setTimeRange(
        _startTime.hour,
        _startTime.minute,
        _endTime.hour,
        _endTime.minute,
      );
    }

    // Update conditions
    routine.conditions = _conditions;

    Navigator.of(context).pop();
    widget.onSave(routine);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
