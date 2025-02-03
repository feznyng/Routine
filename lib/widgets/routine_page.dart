import 'package:flutter/material.dart';
import '../routine.dart';
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
  late Routine _routine;
  bool _isValid = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
   
    _nameController = TextEditingController(text: _routine.name);
    _nameController.addListener(_validateRoutine);

    _checkForChanges();
    _validateRoutine();
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = _routine.modified;
    });
  }

  void _validateRoutine() {
    setState(() {
      _isValid = _routine.modified;
    });
  }

  Future<void> _saveRoutine() async {
    _routine.save();
    widget.onSave(_routine);
  }

  Widget _buildTimeSection() {
    final startTime = TimeOfDay(hour: _routine.startHour, minute: _routine.startMinute);
    final endTime = TimeOfDay(hour: _routine.endHour, minute: _routine.endMinute);

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
            value: _routine.allDay,
            onChanged: (value) {
              setState(() {
                _routine.allDay = value;
                _validateRoutine();
              });
            },
          ),
          if (!_routine.allDay) ...[
            ListTile(
              title: const Text('Start Time'),
              trailing: TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(startTime.format(context)),
                onPressed: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (time != null) {
                    setState(() {
                      _routine.startTime = time.hour * 60 + time.minute;
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
                label: Text(endTime.format(context)),
                onPressed: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (time != null) {
                    setState(() {
                      _routine.endTime = time.hour * 60 + time.minute;
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
                        selected: _routine.days[i],
                        onSelected: (bool selected) {
                          setState(() {
                            _routine.days[i] = selected;
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

  void _toggleBlockGroup() {
    final group = _routine.getGroup()!;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlockGroupPage(
          selectedGroup: group,
          onSave: (group) {
            setState(() {
              _routine.setGroup(group);
              _validateRoutine();
            });
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildBlockGroupSection() {
    String summary = '';
    final group = _routine.getGroup();

    if (group?.name != null) {
      summary = group!.name!;
    } else {
      if (group!.apps.isEmpty && group.sites.isEmpty) {
        summary = group.allow ? 'Everything blocked' : 'Nothing blocked';
      } else {
        List<String> parts = [];
        if (group.apps.isNotEmpty) {
          parts.add('${group.apps.length} app${group.apps.length > 1 ? "s" : ""}');
        }
        if (group.sites.isNotEmpty) {
          parts.add('${group.sites.length} site${group.sites.length > 1 ? "s" : ""}');
        }
        summary = group.allow 
            ? 'Allowing ${parts.join(", ")}'
            : 'Blocking ${parts.join(", ")}';
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
                    hintText: _routine.name.isEmpty ? 'New Routine' : 'Routine Name',
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
              _buildTimeSection()
            ],
          ),
        ),
      ),
    );
  }
}
