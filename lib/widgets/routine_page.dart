import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../routine.dart';
import '../condition.dart';
import '../group.dart';
import 'block_group_page.dart';

class RoutinePage extends StatefulWidget {
  final Routine routine;
  final Function(Routine) onSave;
  final Function()? onDelete;

  const RoutinePage({
    super.key,
    required this.routine,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  late TextEditingController _nameController;
  late List<bool> _selectedDays;
  late bool _isAllDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<Condition> _conditions;
  late String _blockGroupId;
  List<String> _selectedApps = [];
  List<String> _selectedSites = [];
  bool _isValid = false;
  bool _hasChanges = false;
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
    Group? blockGroup = widget.routine.getGroup();

    _blockGroupId = blockGroup.id;
    _selectedApps = List.from(blockGroup.apps);
    _selectedSites = List.from(blockGroup.sites);
    _blockSelected = !blockGroup.allow;
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

    final currentBlockGroup = _blockGroupId.isNotEmpty && 
        Manager().findBlockGroup(_blockGroupId) != null
        ? Manager().findBlockGroup(_blockGroupId)!
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
          _blockGroupId != widget.routine.getGroupId() ||
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlockGroupPage(
          selectedApps: _selectedApps,
          selectedSites: _selectedSites,
          blockSelected: _blockSelected,
          selectedBlockGroupId: _blockGroupId,
          onBlockModeChanged: (value) {
            setState(() {
              _blockSelected = value;
              _validateRoutine();
            });
          },
          onSave: (apps, sites, groupId) {
            setState(() {
              final name = groupId != null ? Manager().findBlockGroup(groupId)?.name : '';

              debugPrint("Saving block group: $groupId $name $sites $apps");
              if (groupId != null) {
                // If a named group is selected, use its current state
                final group = Manager().findBlockGroup(groupId);
                if (group != null) {
                  _selectedApps = List.from(group.apps);
                  _selectedSites = List.from(group.sites);
                  _blockSelected = !group.allow;
                  _blockGroupId = groupId;
                }
              } else {
                // For custom groups, use the provided apps and sites
                _selectedApps = apps;
                _selectedSites = sites;
                _blockGroupId = Manager().tempGroup.id;
              }
              _validateRoutine();
            });
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _saveRoutine() async {
    String? blockGroupId = _blockGroupId == Manager().tempGroup.id ? Uuid().v4() : _blockGroupId;
    
    // Create or update block list
    if (_selectedApps.isNotEmpty || _selectedSites.isNotEmpty) {
      // Preserve the name if updating an existing block list
      String? name;
      final existingBlockGroup = Manager().findBlockGroup(blockGroupId);
      name = existingBlockGroup?.name;

      final blockGroup = Group(
        id: blockGroupId,
        name: name,
        deviceId: Manager().thisDevice.id,
        apps: _selectedApps,
        sites: _selectedSites,
        allow: !_blockSelected,
      );
      Manager().upsertBlockGroup(blockGroup);
    }

    final updatedRoutine = Routine(
      id: widget.routine.id == Manager().tempRoutine.id ? Uuid().v4() : widget.routine.id,
      name: _nameController.text,
      days: _selectedDays,
      startTime: _isAllDay ? -1 : _startTime.hour * 60 + _startTime.minute,
      endTime: _isAllDay ? -1 : _endTime.hour * 60 + _endTime.minute,
      conditions: _conditions,
      groupIds: (_selectedApps.isNotEmpty || _selectedSites.isNotEmpty)
          ? {Manager().thisDevice.id: blockGroupId}
          : {},
    );

    widget.onSave(updatedRoutine);
    // Let the parent handle navigation
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: const Text('Are you sure you want to delete this routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      widget.onDelete?.call();
      Navigator.of(context).pop();
    }
  }

  Widget _buildBlockGroupSection() {
    String summary = '';
    final group = Manager().findBlockGroup(_blockGroupId);

    if (group?.name != null) {
      summary = group!.name!;
    } else {
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
    }

    return Card(
      child: ListTile(
        title: const Text('Block Group'),
        subtitle: Text(summary),
        trailing: const Icon(Icons.chevron_right),
        onTap: _toggleBlockGroup,
      ),
    );
  }

  Widget _buildTimeSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
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
              trailing: TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(_startTime.format(context)),
                onPressed: () async {
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
            ),
            ListTile(
              title: const Text('End Time'),
              trailing: TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(_endTime.format(context)),
                onPressed: () async {
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
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repeat on',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Conditions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_conditions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No conditions added',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _conditions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Condition ${index + 1}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _conditions.removeAt(index);
                      _validateRoutine();
                    });
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  //_conditions.add(Condition());
                  _validateRoutine();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Condition'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: widget.routine.name.isEmpty ? 'New Routine' : 'Routine Name',
                    border: InputBorder.none,
                    isDense: true,
                    suffixIcon: const Icon(Icons.edit, size: 18),
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: (_isValid && _hasChanges) ? _saveRoutine : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBlockGroupSection(),
              const SizedBox(height: 16),
              _buildTimeSection(),
              const SizedBox(height: 16),
              _buildConditionsList(),
              if (widget.onDelete != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Routine', 
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size.fromHeight(64),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
