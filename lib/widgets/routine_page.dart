import 'package:flutter/material.dart';
import '../routine.dart';
import '../database.dart';
import '../setup.dart';
import 'routine_page/index.dart';

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

  late Map<String, DeviceEntry> _devices = {};

  @override
  void initState() {
    super.initState();
    _initializeRoutine();
    _loadDevices();
    _refreshRoutine();
  }

  void _initializeRoutine() {
    _routine = Routine.from(widget.routine);
    _nameController = TextEditingController(text: _routine.name);
    _nameController.addListener(_validateRoutine);
    _validateRoutine();
  }

  Future<void> _refreshRoutine() async {
    if (_routine.saved) {
      final routines = await getIt<AppDatabase>().getRoutinesById([_routine.id]);
      if (routines.isNotEmpty) {
        final routine = routines.first;
        final groups = await getIt<AppDatabase>().getGroupsById(routine.groups);
        setState(() {
          _routine = Routine.fromEntry(routine, groups);
          _nameController.text = _routine.name;
          _validateRoutine();
        });
      }
    }
  }

  Future<void> _loadDevices() async {
    final devices = Map.fromEntries(
      (await getIt<AppDatabase>().getDevices()).map((e) => MapEntry(e.id, e)),
    );

    setState(() {
      _devices = devices;
    });
  }

  @override
  void didUpdateWidget(RoutinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine != widget.routine) {
      _nameController.dispose();
      _initializeRoutine();
      _refreshRoutine();
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

  // All widget sections have been moved to separate files


  // All widget sections have been moved to separate files

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
              BlockGroupSection(
                routine: _routine,
                devices: _devices,
                onChanged: _validateRoutine,
              ),
              const SizedBox(height: 16),
              TimeSection(
                routine: _routine,
                onChanged: _validateRoutine,
              ),
              const SizedBox(height: 16),
              BreakConfigSection(
                routine: _routine,
                onChanged: _validateRoutine,
              ),
              const SizedBox(height: 16),
              ConditionSection(
                routine: _routine,
                onChanged: _validateRoutine,
              ),
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
