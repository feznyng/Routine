import 'package:flutter/material.dart';
import '../../routine.dart';
import '../../condition.dart';

class ConditionSection extends StatelessWidget {
  final Routine routine;
  final Function() onChanged;

  const ConditionSection({
    super.key,
    required this.routine,
    required this.onChanged,
  });

  String _getConditionTypeLabel(ConditionType type) {
    switch (type) {
      case ConditionType.location:
        return 'Location';
      case ConditionType.nfc:
        return 'NFC Tag';
      case ConditionType.qr:
        return 'QR Code';
      case ConditionType.health:
        return 'Health Activity';
      case ConditionType.todo:
        return 'To-Do Task';
    }
  }

  IconData _getConditionTypeIcon(ConditionType type) {
    switch (type) {
      case ConditionType.location:
        return Icons.location_on;
      case ConditionType.nfc:
        return Icons.nfc;
      case ConditionType.qr:
        return Icons.qr_code;
      case ConditionType.health:
        return Icons.fitness_center;
      case ConditionType.todo:
        return Icons.check_circle_outline;
    }
  }

  String _getConditionSummary(Condition condition) {
    switch (condition.type) {
      case ConditionType.location:
        return condition.location ?? 'No location set';
      case ConditionType.nfc:
      case ConditionType.qr:
        return condition.nfcQrCode ?? 'No code set';
      case ConditionType.health:
        if (condition.activityType != null && condition.activityAmt != null) {
          return '${condition.activityType}: ${condition.activityAmt}';
        }
        return 'No activity set';
      case ConditionType.todo:
        return condition.todoText ?? 'No task set';
    }
  }

  void _editCondition(BuildContext context, Condition condition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ConditionEditSheet(
        condition: condition,
        onSave: (updatedCondition) {
          int index = routine.conditions.indexWhere((c) => c.id == condition.id);
          if (index >= 0) {
            routine.conditions[index] = updatedCondition;
            onChanged();
          }
          Navigator.pop(context);
        },
        onDelete: () {
          routine.conditions.removeWhere((c) => c.id == condition.id);
          onChanged();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addCondition(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Condition Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ConditionType.values.map((type) {
              return ListTile(
                leading: Icon(_getConditionTypeIcon(type)),
                title: Text(_getConditionTypeLabel(type)),
                onTap: () {
                  Navigator.pop(context);
                  final newCondition = Condition.create(type: type);
                  routine.conditions.add(newCondition);
                  _editCondition(context, newCondition);
                },
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        child: SingleChildScrollView(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Conditions must be met before the routine becomes active',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              if (routine.conditions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No conditions added',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routine.conditions.length,
                  itemBuilder: (context, index) {
                    final condition = routine.conditions[index];
                    return ListTile(
                      leading: Icon(_getConditionTypeIcon(condition.type)),
                      title: Text(_getConditionTypeLabel(condition.type)),
                      subtitle: Text(_getConditionSummary(condition)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _editCondition(context, condition),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _addCondition(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Condition'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionEditSheet extends StatefulWidget {
  final Condition condition;
  final Function(Condition) onSave;
  final Function() onDelete;

  const _ConditionEditSheet({
    required this.condition,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_ConditionEditSheet> createState() => _ConditionEditSheetState();
}

class _ConditionEditSheetState extends State<_ConditionEditSheet> {
  late Condition _condition;
  late TextEditingController _locationController;
  late TextEditingController _nfcQrCodeController;
  late TextEditingController _activityTypeController;
  late TextEditingController _activityAmtController;
  late TextEditingController _todoTextController;

  @override
  void initState() {
    super.initState();
    // Create a new condition with the same values instead of using fromJson
    _condition = Condition(
      id: widget.condition.id,
      type: widget.condition.type,
      location: widget.condition.location,
      nfcQrCode: widget.condition.nfcQrCode,
      activityType: widget.condition.activityType,
      activityAmt: widget.condition.activityAmt,
      todoText: widget.condition.todoText,
      completedAt: widget.condition.lastCompletedAt
    );
    _locationController = TextEditingController(text: _condition.location ?? '');
    _nfcQrCodeController = TextEditingController(text: _condition.nfcQrCode ?? '');
    _activityTypeController = TextEditingController(text: _condition.activityType ?? '');
    _activityAmtController = TextEditingController(text: _condition.activityAmt ?? '');
    _todoTextController = TextEditingController(text: _condition.todoText ?? '');
  }

  @override
  void dispose() {
    _locationController.dispose();
    _nfcQrCodeController.dispose();
    _activityTypeController.dispose();
    _activityAmtController.dispose();
    _todoTextController.dispose();
    super.dispose();
  }

  String _getConditionTypeLabel(ConditionType type) {
    switch (type) {
      case ConditionType.location:
        return 'Location';
      case ConditionType.nfc:
        return 'NFC Tag';
      case ConditionType.qr:
        return 'QR Code';
      case ConditionType.health:
        return 'Health Activity';
      case ConditionType.todo:
        return 'To-Do Task';
    }
  }

  IconData _getConditionTypeIcon(ConditionType type) {
    switch (type) {
      case ConditionType.location:
        return Icons.location_on;
      case ConditionType.nfc:
        return Icons.nfc;
      case ConditionType.qr:
        return Icons.qr_code;
      case ConditionType.health:
        return Icons.fitness_center;
      case ConditionType.todo:
        return Icons.check_circle_outline;
    }
  }

  Widget _buildConditionFields() {
    switch (_condition.type) {
      case ConditionType.location:
        return TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location',
            hintText: 'Enter location name',
          ),
          onChanged: (value) {
            _condition.location = value;
          },
        );
      case ConditionType.nfc:
      case ConditionType.qr:
        return TextField(
          controller: _nfcQrCodeController,
          decoration: InputDecoration(
            labelText: _condition.type == ConditionType.nfc ? 'NFC Tag ID' : 'QR Code',
            hintText: _condition.type == ConditionType.nfc ? 'Enter NFC tag ID' : 'Enter QR code',
          ),
          onChanged: (value) {
            _condition.nfcQrCode = value;
          },
        );
      case ConditionType.health:
        return Column(
          children: [
            TextField(
              controller: _activityTypeController,
              decoration: const InputDecoration(
                labelText: 'Activity Type',
                hintText: 'E.g., Steps, Running, etc.',
              ),
              onChanged: (value) {
                _condition.activityType = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _activityAmtController,
              decoration: const InputDecoration(
                labelText: 'Activity Amount',
                hintText: 'E.g., 5000 steps, 30 minutes, etc.',
              ),
              onChanged: (value) {
                _condition.activityAmt = value;
              },
            ),
          ],
        );
      case ConditionType.todo:
        return TextField(
          controller: _todoTextController,
          decoration: const InputDecoration(
            labelText: 'Task',
            hintText: 'Enter task description',
          ),
          onChanged: (value) {
            _condition.todoText = value;
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getConditionTypeIcon(_condition.type)),
                  const SizedBox(width: 8),
                  Text(
                    'Edit ${_getConditionTypeLabel(_condition.type)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConditionFields(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onSave(_condition),
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
