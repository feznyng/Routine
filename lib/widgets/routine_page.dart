import 'package:flutter/material.dart';
import '../routine.dart';
import 'block_group_page.dart';
import '../database.dart';

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
    _initializeRoutine();
  }

  void _initializeRoutine() {
    _routine = Routine.from(widget.routine);
    _nameController = TextEditingController(text: _routine.name);
    _nameController.addListener(_validateRoutine);
    _validateRoutine();
  }

  @override
  void didUpdateWidget(RoutinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine != widget.routine) {
      _nameController.dispose();
      _initializeRoutine();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateRoutine() {
    setState(() {
      _isValid = _routine.valid;
      _hasChanges = _routine.modified;
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

  Widget _buildBreakConfigSection() {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 300),
        child: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Breaks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Max Breaks'),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Unlimited'),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Limited'),
                    ),
                  ],
                  selected: {_routine.maxBreaks != null},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _routine.maxBreaks = selection.first ? 3 : null;
                      _validateRoutine();
                    });
                  },
                ),
                if (_routine.maxBreaks != null) ...[                
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'minus',
                        icon: const Icon(Icons.remove),
                        enabled: _routine.maxBreaks! > 1,
                      ),
                      ButtonSegment(
                        value: 'text',
                        label: Text('${_routine.maxBreaks} breaks'),
                      ),
                      ButtonSegment(
                        value: 'plus',
                        icon: const Icon(Icons.add),
                        enabled: _routine.maxBreaks! < 10,
                      ),
                    ],
                    emptySelectionAllowed: true,
                    selected: const {},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        if (selected.first == 'minus' && _routine.maxBreaks! > 1) {
                          _routine.maxBreaks = _routine.maxBreaks! - 1;
                        } else if (selected.first == 'plus' && _routine.maxBreaks! < 10) {
                          _routine.maxBreaks = _routine.maxBreaks! + 1;
                        }
                        _validateRoutine();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Break Duration'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'minus',
                      icon: const Icon(Icons.remove),
                      enabled: _routine.maxBreakDuration > 5,
                    ),
                    ButtonSegment(
                      value: 'text',
                      label: Text('${_routine.maxBreakDuration} min'),
                    ),
                    ButtonSegment(
                      value: 'plus',
                      icon: const Icon(Icons.add),
                      enabled: _routine.maxBreakDuration < 60,
                    ),
                  ],
                  emptySelectionAllowed: true,
                  selected: const {},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() {
                      if (selected.first == 'minus' && _routine.maxBreakDuration > 5) {
                        _routine.maxBreakDuration = _routine.maxBreakDuration - 5;
                      } else if (selected.first == 'plus' && _routine.maxBreakDuration < 60) {
                        _routine.maxBreakDuration = _routine.maxBreakDuration + 5;
                      }
                      _validateRoutine();
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Friction'),
                const SizedBox(height: 8),
                SegmentedButton<FrictionType>(
                  segments: const [
                    ButtonSegment(
                      value: FrictionType.none,
                      label: Text('None'),
                    ),
                    ButtonSegment(
                      value: FrictionType.delay,
                      label: Text('Delay'),
                    ),
                    ButtonSegment(
                      value: FrictionType.intention,
                      label: Text('Intention'),
                    ),
                    ButtonSegment(
                      value: FrictionType.code,
                      label: Text('Code'),
                    ),
                  ],
                  selected: {_routine.friction},
                  onSelectionChanged: (Set<FrictionType> selection) {
                    setState(() {
                      _routine.friction = selection.first;
                      if (_routine.friction == FrictionType.none || 
                          _routine.friction == FrictionType.intention) {
                        _routine.frictionLen = null;
                      }
                      _validateRoutine();
                    });
                  },
                ),
                if (_routine.friction == FrictionType.delay || _routine.friction == FrictionType.code) ...[                
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(_routine.friction == FrictionType.delay ? 'Delay Length' : 'Code Length'),
                      const SizedBox(width: 8)
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Automatic'),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Fixed'),
                      ),
                    ],
                    selected: {_routine.frictionLen != null},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        _routine.frictionLen = selection.first 
                          ? (_routine.friction == FrictionType.delay ? 30 : 6)
                          : null;
                        _validateRoutine();
                      });
                    },
                  ),
                  if (_routine.frictionLen != null) ...[                
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'minus',
                          icon: const Icon(Icons.remove),
                          enabled: _routine.frictionLen! > (_routine.friction == FrictionType.delay ? 5 : 4),
                        ),
                        ButtonSegment(
                          value: 'text',
                          label: Text(_routine.friction == FrictionType.delay 
                            ? '${_routine.frictionLen} sec'
                            : '${_routine.frictionLen} chars'),
                        ),
                        ButtonSegment(
                          value: 'plus',
                          icon: const Icon(Icons.add),
                          enabled: _routine.frictionLen! < (_routine.friction == FrictionType.delay ? 60 : 12),
                        ),
                      ],
                      emptySelectionAllowed: true,
                      selected: const {},
                      onSelectionChanged: (Set<String> selected) {
                        setState(() {
                          if (selected.first == 'minus' && 
                              _routine.frictionLen! > (_routine.friction == FrictionType.delay ? 5 : 4)) {
                            _routine.frictionLen = _routine.frictionLen! - (_routine.friction == FrictionType.delay ? 5 : 1);
                          } else if (selected.first == 'plus' && 
                              _routine.frictionLen! < (_routine.friction == FrictionType.delay ? 60 : 12)) {
                            _routine.frictionLen = _routine.frictionLen! + (_routine.friction == FrictionType.delay ? 5 : 1);
                          }
                          _validateRoutine();
                        });
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    )));
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: (value) {
                    setState(() {
                      _routine.name = value;
                      _validateRoutine();
                    });
                  },
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
              _buildTimeSection(),
              const SizedBox(height: 16),
              _buildBreakConfigSection(),
              const SizedBox(height: 32),
              if (_routine.saved) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete Routine', style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      final BuildContext dialogContext = context;
                      final bool? confirm = await showDialog<bool>(
                        context: dialogContext,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Routine'),
                            content: const Text('Are you sure you want to delete this routine?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (confirm == true) {
                        await _routine.delete();
                        if (mounted && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
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
