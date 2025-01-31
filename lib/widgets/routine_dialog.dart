import 'package:flutter/material.dart';
import '../routine.dart';
import '../condition.dart';
import '../group.dart';
import '../manager.dart';
import 'block_group_page.dart';
import 'package:uuid/uuid.dart';

class RoutineDialog extends StatefulWidget {
  final Routine routine;
  final Function(Routine) onSave;
  final Function()? onDelete;

  const RoutineDialog({
    super.key,
    required this.routine,
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
  List<String> _selectedApps = [];
  List<String> _selectedSites = [];
  String? _blockGroupId;
  bool _isValid = false;
  bool _hasChanges = false;
  bool _showBlockGroup = false;
  bool _blockSelected = true;  // true = blockgroup mode, false = allowlist mode

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _selectedDays = List.from(widget.routine.days);
    _isAllDay = widget.routine.startTime == -1;
    _startTime = widget.routine.startTime != -1
        ? TimeOfDay(
            hour: widget.routine.startHour,
            minute: widget.routine.startMinute,
          )
        : const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.routine.endTime != -1
        ? TimeOfDay(
            hour: widget.routine.endHour,
            minute: widget.routine.endMinute,
          )
        : const TimeOfDay(hour: 17, minute: 0);
    _conditions = List.from(widget.routine.conditions);

    // Load block list if exists
    _blockGroupId = widget.routine.getGroupId();
    if (_blockGroupId != null && _blockGroupId!.isNotEmpty && Manager().findBlockGroup(_blockGroupId!) != null) {
      final blockGroup = Manager().findBlockGroup(_blockGroupId!)!;
      _selectedApps = List.from(blockGroup.apps);
      _selectedSites = List.from(blockGroup.sites);
      _blockSelected = !blockGroup.allow;
    }
    
    _nameController.addListener(_validateRoutine);
    _validateRoutine();
  }

  void _checkForChanges() {
    bool daysEqual = _selectedDays.length == widget.routine.days.length &&
        List.generate(_selectedDays.length, (i) => _selectedDays[i] == widget.routine.days[i])
            .every((element) => element);

    bool startTimeEqual = _isAllDay == (widget.routine.startTime == -1) &&
        (_isAllDay || 
         (_startTime.hour * 60 + _startTime.minute == widget.routine.startTime));

    bool endTimeEqual = _isAllDay == (widget.routine.endTime == -1) &&
        (_isAllDay || 
         (_endTime.hour * 60 + _endTime.minute == widget.routine.endTime));

    // Get current block list for comparison
    final currentBlockGroup = _blockGroupId != null && _blockGroupId!.isNotEmpty && 
        Manager().findBlockGroup(_blockGroupId!) != null
        ? Manager().findBlockGroup(_blockGroupId!)!
        : null;

    bool appsEqual = currentBlockGroup != null &&
        _selectedApps.length == currentBlockGroup.apps.length &&
        _selectedApps.every((app) => currentBlockGroup.apps.contains(app));

    bool sitesEqual = currentBlockGroup != null &&
        _selectedSites.length == currentBlockGroup.sites.length &&
        _selectedSites.every((site) => currentBlockGroup.sites.contains(site));

    bool blockModeEqual = currentBlockGroup != null &&
        _blockSelected == !currentBlockGroup.allow;

    setState(() {
      _hasChanges = _nameController.text != widget.routine.name ||
          !daysEqual ||
          !startTimeEqual ||
          !endTimeEqual ||
          _conditions.length != widget.routine.conditions.length ||
          !appsEqual ||
          !sitesEqual ||
          !blockModeEqual;
    });
  }

  void _validateRoutine() {
    _checkForChanges();
    setState(() {
      _isValid = _nameController.text.isNotEmpty && 
                 _selectedDays.contains(true);
    });
  }

  void _toggleBlockGroup() {
    setState(() {
      _showBlockGroup = !_showBlockGroup;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: 600,
        height: 500,
        child: _showBlockGroup
            ? BlockGroupPage(
                selectedApps: _selectedApps,
                selectedSites: _selectedSites,
                blockSelected: _blockSelected,
                onBlockModeChanged: (value) {
                  setState(() {
                    _blockSelected = value;
                  });
                },
                onSave: (apps, sites) {
                  setState(() {
                    _selectedApps = apps;
                    _selectedSites = sites;
                    _validateRoutine();
                  });
                },
                onBack: _toggleBlockGroup,
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Routine Name'),
                    ),
                    const SizedBox(height: 16),
                    _buildBlockGroupSection(),
                    const SizedBox(height: 16),
                    _buildTimeSection(),
                    const SizedBox(height: 16),
                    _buildDaySelector(),
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
      ),
      actions: _showBlockGroup ? [] : [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (_isValid && (_hasChanges)) ? _saveRoutine : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
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
      ),
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

  Widget _buildBlockGroupSection() {
    String summary = '';
    if (_selectedApps.isEmpty && _selectedSites.isEmpty) {
      summary = _blockSelected ? 'Nothing blocked' : 'Everything blocked';
    } else {
      List<String> parts = [];
      if (_selectedApps.isNotEmpty) {
        parts.add('${_selectedApps.length} apps');
      }
      if (_selectedSites.isNotEmpty) {
        parts.add('${_selectedSites.length} sites');
      }
      summary = _blockSelected 
          ? 'Blocking ${parts.join(", ")}'
          : 'Allowing ${parts.join(", ")}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleBlockGroup,
          child: Card(
            child: ListTile(
              title: Text(
                'Block Group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(summary),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Unlock Conditions'),
        const SizedBox(height: 8),
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
    final routine = _createRoutine();
    Navigator.of(context).pop();
    widget.onSave(routine);
  }

  Routine _createRoutine() {
    // Convert TimeOfDay to minutes since midnight
    final startTimeMinutes = !_isAllDay ? _startTime.hour * 60 + _startTime.minute : -1;
    final endTimeMinutes = !_isAllDay ? _endTime.hour * 60 + _endTime.minute : -1;
    
    // Create immutable block list
    final blockGroup = Group(
      id: Uuid().v4(),
      name: _nameController.text,
      deviceId: Manager().thisDevice.id,
      apps: _selectedApps,
      sites: _selectedSites,
      allowList: !_blockSelected
    );

    // Add block list to manager
    Manager().upsertBlockGroup(blockGroup);
    
    // Create immutable routine with all properties
    return Routine(
      id: widget.routine.id,
      name: _nameController.text,
      days: List.from(_selectedDays),
      startTime: startTimeMinutes,
      endTime: endTimeMinutes,
      numBreaks: widget.routine.numBreaks,
      maxBreakDuration: widget.routine.maxBreakDuration,
      frictionType: widget.routine.frictionType,
      frictionNum: widget.routine.frictionNum,
      frictionSource: widget.routine.frictionSource,
      conditions: List.from(_conditions),
      groupIds: {Manager().thisDevice.id: _blockGroupId!}
    );
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
