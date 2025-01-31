import 'package:flutter/material.dart';
import '../routine.dart';
import '../condition.dart';
import '../group.dart';
import '../manager.dart';
import 'block_group_page.dart';
import 'package:uuid/uuid.dart';

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
  List<String> _selectedApps = [];
  List<String> _selectedSites = [];
  String? _blockListId;
  bool _isValid = false;
  bool _hasChanges = false;
  bool _blockSelected = true;  // true = blocklist mode, false = allowlist mode

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
    _blockListId = widget.routine.groupIds[Manager().thisDevice.id];
    if (_blockListId != null && _blockListId!.isNotEmpty && Manager().findBlockList(_blockListId!) != null) {
      final blockList = Manager().findBlockList(_blockListId!)!;
      _selectedApps = List.from(blockList.apps);
      _selectedSites = List.from(blockList.sites);
      _blockSelected = !blockList.allow;
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

    final currentBlockList = _blockListId != null && _blockListId!.isNotEmpty && 
        Manager().findBlockList(_blockListId!) != null
        ? Manager().findBlockList(_blockListId!)!
        : null;

    bool appsEqual = currentBlockList != null &&
        _selectedApps.length == currentBlockList.apps.length &&
        _selectedApps.every((app) => currentBlockList.apps.contains(app));

    bool sitesEqual = currentBlockList != null &&
        _selectedSites.length == currentBlockList.sites.length &&
        _selectedSites.every((site) => currentBlockList.sites.contains(site));

    bool blockModeEqual = currentBlockList != null &&
        _blockSelected == !currentBlockList.allow;

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

  void _toggleBlockList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlockGroupPage(
          selectedApps: _selectedApps,
          selectedSites: _selectedSites,
          blockSelected: _blockSelected,
          selectedBlockListId: _blockListId,
          onBlockModeChanged: (value) {
            setState(() {
              _blockSelected = value;
              _validateRoutine();
            });
          },
          onSave: (apps, sites) {
            setState(() {
              _selectedApps = apps;
              _selectedSites = sites;
              _validateRoutine();
            });
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _saveRoutine() async {
    // Use existing block list ID if available, otherwise create a new one
    String blockListId = _blockListId ?? const Uuid().v4();
    
    // Create or update block list
    if (_selectedApps.isNotEmpty || _selectedSites.isNotEmpty) {
      // Preserve the name if updating an existing block list
      String? name;
      if (_blockListId != null) {
        final existingBlockList = Manager().findBlockList(_blockListId!);
        name = existingBlockList?.name;
      }

      final blockList = Group(
        id: blockListId,
        name: name,
        deviceId: Manager().thisDevice.id,
        apps: _selectedApps,
        sites: _selectedSites,
        allowList: !_blockSelected,
      );
      Manager().upsertBlockList(blockList);
    }

    final updatedRoutine = Routine(
      id: widget.routine.id,
      name: _nameController.text,
      days: _selectedDays,
      startTime: _isAllDay ? -1 : _startTime.hour * 60 + _startTime.minute,
      endTime: _isAllDay ? -1 : _endTime.hour * 60 + _endTime.minute,
      conditions: _conditions,
      groupIds: (_selectedApps.isNotEmpty || _selectedSites.isNotEmpty) ? {Manager().thisDevice.id: _blockListId!} : {},
    );

    widget.onSave(updatedRoutine);
    Navigator.of(context).pop();
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

  Widget _buildBlockListSection() {
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

    return Card(
      child: ListTile(
        title: const Text('Block Group'),
        subtitle: Text(summary),
        trailing: const Icon(Icons.chevron_right),
        onTap: _toggleBlockList,
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
              _buildBlockListSection(),
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
