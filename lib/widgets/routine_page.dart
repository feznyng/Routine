import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../database/database.dart';
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
  bool _originalStrictMode = false;
  bool _originalIsActive = false;

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
    _originalStrictMode = _routine.strictMode;
    _originalIsActive = _routine.isActive;
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
          _originalStrictMode = _routine.strictMode;
          _originalIsActive = _routine.isActive;
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
  
  String _formatDateTime(DateTime dateTime) {
    // Convert to local time if in UTC
    if (dateTime.isUtc) {
      dateTime = dateTime.toLocal();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
        
    String dateStr;
    if (dateToCheck.isAtSameMomentAs(today)) {
      dateStr = 'Today';
    } else if (dateToCheck.isAtSameMomentAs(tomorrow)) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
    
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$dateStr at $hour:$minute $period';
  }

  Future<void> _saveRoutine() async {
    // If strict mode is being enabled, show a confirmation dialog
    if (!_originalStrictMode && _routine.strictMode) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Save Routine'),
            content: const Text(
              'You are enabling strict mode for this routine. When this routine is active, you will not be able to modify or delete it, and other restrictions will be enforced. Are you sure you want to continue?'
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save Routine'),
              ),
            ],
          );
        },
      );
      
      if (confirm != true) {
        return;
      }
    }
    
    _routine.save();
    _originalStrictMode = _routine.strictMode;
    _originalIsActive = _routine.isActive;
    widget.onSave(_routine);
  }

  @override
  Widget build(BuildContext context) {
    final inLockdown = _originalIsActive && _originalStrictMode;

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
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixIcon: const Icon(Icons.edit, size: 18),
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                  enabled: true, // Always enable the title field
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: (_isValid && _hasChanges) ? _saveRoutine : null, // Always allow saving if valid and has changes
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
              if (inLockdown) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Strict Mode Active',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'This routine is currently active and in strict mode. You cannot make changes until the routine becomes inactive.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              BlockGroupSection(
                routine: _routine,
                devices: _devices,
                onChanged: _validateRoutine,
                enabled: !inLockdown,
              ),
              const SizedBox(height: 16),
              TimeSection(
                routine: _routine,
                onChanged: _validateRoutine,
                enabled: !inLockdown,
              ),
              const SizedBox(height: 16),
              ConditionSection(
                routine: _routine,
                onChanged: _validateRoutine,
                enabled: !inLockdown,
              ),
              const SizedBox(height: 16),
              BreakConfigSection(
                routine: _routine,
                onChanged: _validateRoutine,
                enabled: !inLockdown,
              ),
              const SizedBox(height: 16),
              StrictModeSection(
                routine: _routine,
                onChanged: _validateRoutine,
                enabled: !inLockdown,
              ),
              const SizedBox(height: 32),
              if (_routine.saved) ...[
                // Snooze Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    icon: Icon(
                      _routine.isSnoozed ? Icons.alarm_off : Icons.snooze,
                      color: (!_routine.isSnoozed && _originalStrictMode)
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 128)
                          : Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      _routine.isSnoozed 
                        ? 'Unsnooze Routine (Snoozed until ${_formatDateTime(_routine.snoozedUntil!)})'
                        : 'Snooze Routine',
                      style: TextStyle(
                        color: (!_routine.isSnoozed && _originalStrictMode)
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 128)
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onPressed: (!_routine.isSnoozed && _originalStrictMode)
                        ? null
                        : () async {
                      if (_routine.isSnoozed) {
                        // Unsnooze the routine
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Unsnooze Routine'),
                              content: const Text('Are you sure you want to unsnooze this routine?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Unsnooze'),
                                ),
                              ],
                            );
                          },
                        );
                        
                        if (confirm == true) {
                          await _routine.unsnooze();
                          setState(() {
                            _validateRoutine();
                          });
                        }
                      } else {
                        // Show date picker to snooze the routine
                        final DateTime? selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        
                        if (selectedDate != null) {
                          // Show time picker
                          final TimeOfDay? selectedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          
                          if (selectedTime != null) {
                            // Combine date and time
                            final DateTime snoozeUntil = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            
                            await _routine.snooze(snoozeUntil);
                            setState(() {
                              _validateRoutine();
                            });
                          }
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Delete Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    icon: Icon(Icons.delete_outline, color: _originalStrictMode ? Colors.red.withValues(alpha: 128) : Colors.red),
                    label: Text('Delete Routine', style: TextStyle(color: _originalStrictMode ? Colors.red.withValues(alpha: 128) : Colors.red)),
                    onPressed: _originalStrictMode ? null : () async {
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
