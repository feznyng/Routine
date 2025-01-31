import 'package:flutter/material.dart';
import '../routine.dart';
import '../condition.dart';
import '../block_list.dart';
import '../manager.dart';
import 'block_list_page.dart';
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
    _blockListId = widget.routine.blockId;
    if (_blockListId != null && _blockListId!.isNotEmpty && Manager().findBlockList(_blockListId!) != null) {
      final blockList = Manager().findBlockList(_blockListId!)!;
      _selectedApps = List.from(blockList.apps);
      _selectedSites = List.from(blockList.sites);
      _blockSelected = !blockList.allowList;
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
        _blockSelected == !currentBlockList.allowList;

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
        builder: (context) => BlockListPage(
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
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _saveRoutine() async {
    String blockListId = _blockListId ?? const Uuid().v4();
    
    // Create or update block list
    if (_selectedApps.isNotEmpty || _selectedSites.isNotEmpty) {
      final blockList = BlockList(
        id: blockListId,
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
      blockId: (_selectedApps.isNotEmpty || _selectedSites.isNotEmpty) ? blockListId : '',
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

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time'),
        const SizedBox(height: 8),
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

  Widget _buildDaySelector() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Days'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            return FilterChip(
              label: Text(days[index]),
              selected: _selectedDays[index],
              onSelected: (selected) {
                setState(() {
                  _selectedDays[index] = selected;
                  _validateRoutine();
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBlockListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _toggleBlockList,
          icon: const Icon(Icons.block),
          label: Text(_selectedApps.isEmpty && _selectedSites.isEmpty
              ? 'Add List'
              : 'Edit List'),
        ),
        if (_selectedApps.isNotEmpty || _selectedSites.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_blockSelected ? "Blocking" : "Allowing"} ${_selectedApps.length} apps'
            '${_selectedSites.isNotEmpty ? " and ${_selectedSites.length} sites" : ""}',
            style: Theme.of(context).textTheme.bodySmall,
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _validateRoutine();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Condition'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBlockListSection(),
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
    );
  }
}
