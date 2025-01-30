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
  bool _isValid = false;
  bool _hasChanges = false;

  // Store initial values for comparison
  String? _initialName;
  List<bool>? _initialDays;
  bool? _initialIsAllDay;
  TimeOfDay? _initialStartTime;
  TimeOfDay? _initialEndTime;
  List<Condition>? _initialConditions;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.name ?? '');
    _selectedDays = widget.routine?.days ?? List.filled(7, true);
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

    // Store initial values
    if (widget.routine != null) {
      _initialName = widget.routine!.name;
      _initialDays = List.from(widget.routine!.days);
      _initialIsAllDay = widget.routine!.startTime == -1;
      _initialStartTime = widget.routine!.startTime != -1
          ? TimeOfDay(
              hour: widget.routine!.startHour,
              minute: widget.routine!.startMinute,
            )
          : null;
      _initialEndTime = widget.routine!.endTime != -1
          ? TimeOfDay(
              hour: widget.routine!.endHour,
              minute: widget.routine!.endMinute,
            )
          : null;
      _initialConditions = List.from(widget.routine!.conditions);
    }
    
    _nameController.addListener(_validateRoutine);
    _validateRoutine();
  }

  void _checkForChanges() {
    if (widget.routine == null) {
      _hasChanges = true;
      return;
    }

    bool daysEqual = _initialDays != null && 
        _selectedDays.length == _initialDays!.length &&
        List.generate(_selectedDays.length, (i) => _selectedDays[i] == _initialDays![i])
            .every((element) => element);

    bool startTimeEqual = _isAllDay == _initialIsAllDay &&
        (_isAllDay || 
         (_startTime.hour == _initialStartTime?.hour && 
          _startTime.minute == _initialStartTime?.minute));

    bool endTimeEqual = _isAllDay == _initialIsAllDay &&
        (_isAllDay || 
         (_endTime.hour == _initialEndTime?.hour && 
          _endTime.minute == _initialEndTime?.minute));

    setState(() {
      _hasChanges = _nameController.text != _initialName ||
          !daysEqual ||
          !startTimeEqual ||
          !endTimeEqual ||
          _conditions.length != _initialConditions?.length;
    });
  }

  void _validateRoutine() {
    _checkForChanges();
    setState(() {
      _isValid = _nameController.text.isNotEmpty && 
                 _selectedDays.contains(true);
    });
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
            if (widget.onDelete != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Routine', 
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (_isValid && (_hasChanges || widget.routine == null)) ? _saveRoutine : null,
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
                _validateRoutine();
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
              _validateRoutine();
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
                  _validateRoutine();
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
                  _validateRoutine();
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
          const Text('None', style: TextStyle(fontStyle: FontStyle.italic)),
        ..._conditions.map((condition) => ListTile(
              title: Text(condition.runtimeType.toString()),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _conditions.remove(condition);
                    _validateRoutine();
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

  void _confirmDelete() {
    Navigator.of(context).pop(); // Close routine dialog first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: const Text('Are you sure you want to delete this routine? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              widget.onDelete!();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
