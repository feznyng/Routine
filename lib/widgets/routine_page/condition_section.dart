import 'package:flutter/material.dart';
import '../../routine.dart';
import '../../condition.dart';
import '../../util.dart';

class ConditionSection extends StatelessWidget {
  final Routine routine;
  final Function() onChanged;
  final bool enabled;

  const ConditionSection({
    super.key,
    required this.routine,
    required this.onChanged,
    this.enabled = true,
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
    // If the condition has a name, use it as the summary for any condition type
    if (condition.name != null && condition.name!.isNotEmpty) {
      return '${condition.name!} (${condition.proximity!.toInt()} m)';
    }
    
    // Otherwise, use the default summary based on condition type
    switch (condition.type) {
      case ConditionType.location:
        if (condition.latitude != null && condition.longitude != null) {
          final proximity = condition.proximity != null ? ' (${condition.proximity!.toInt()}m radius)' : '';
          return 'Location$proximity';
        }
        return 'No location set';
      case ConditionType.nfc:
      case ConditionType.qr:
        return condition.nfcQrCode ?? 'No code set';
      case ConditionType.health:
        if (condition.activityType != null && condition.activityAmt != null) {
          return '${condition.activityType}: ${condition.activityAmt}';
        }
        return 'No activity set';
      case ConditionType.todo:
        return condition.name ?? 'No task set';
    }
  }

  void _editCondition(BuildContext context, Condition condition) {
    if (!enabled) return;
    
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
    if (!enabled) return;
    
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
                  'Conditions must be met to disable blocking.',
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
                      onTap: enabled ? () => _editCondition(context, condition) : null,
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: enabled ? () => _addCondition(context) : null,
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
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _proximityController;
  late TextEditingController _nfcQrCodeController;
  late TextEditingController _activityTypeController;
  late TextEditingController _activityAmtController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // Create a new condition with the same values instead of using fromJson
    _condition = Condition(
      id: widget.condition.id,
      type: widget.condition.type,
      latitude: widget.condition.latitude,
      longitude: widget.condition.longitude,
      proximity: widget.condition.proximity,
      nfcQrCode: widget.condition.nfcQrCode,
      activityType: widget.condition.activityType,
      activityAmt: widget.condition.activityAmt,
      name: widget.condition.name,
      completedAt: widget.condition.lastCompletedAt
    );
    _latitudeController = TextEditingController(text: _condition.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: _condition.longitude?.toString() ?? '');
    _proximityController = TextEditingController(text: _condition.proximity?.toString() ?? '100');
    _nfcQrCodeController = TextEditingController(text: _condition.nfcQrCode ?? '');
    _activityTypeController = TextEditingController(text: _condition.activityType ?? '');
    _activityAmtController = TextEditingController(text: _condition.activityAmt ?? '');
    _nameController = TextEditingController(text: _condition.name ?? '');
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _proximityController.dispose();
    _nfcQrCodeController.dispose();
    _activityTypeController.dispose();
    _activityAmtController.dispose();
    _nameController.dispose();
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
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text('Get Current Location'),
                    onPressed: () async {
                      try {
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Getting your current location...')),
                        );
                        
                        // Get the current position
                        final position = await Util.determinePosition();
                        
                        // Update the UI
                        setState(() {
                          _latitudeController.text = position.latitude.toString();
                          _longitudeController.text = position.longitude.toString();
                          _condition.latitude = position.latitude;
                          _condition.longitude = position.longitude;
                        });
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location updated successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error getting location: $e')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'Enter latitude',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  try {
                    _condition.latitude = double.parse(value);
                  } catch (e) {
                    // Handle parsing error
                  }
                } else {
                  _condition.latitude = null;
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'Enter longitude',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  try {
                    _condition.longitude = double.parse(value);
                  } catch (e) {
                    // Handle parsing error
                  }
                } else {
                  _condition.longitude = null;
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _proximityController,
              decoration: const InputDecoration(
                labelText: 'Proximity (meters)',
                hintText: 'Enter proximity radius in meters',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  try {
                    _condition.proximity = double.parse(value);
                  } catch (e) {
                    // Handle parsing error
                  }
                } else {
                  _condition.proximity = 100; // Default to 100 meters
                }
              },
            ),
          ],
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
        // For todo type, we already have the name field at the top of the form
        // that serves as both the name and the task description
        return const SizedBox.shrink();
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter a name or description for this condition',
            ),
            onChanged: (value) {
              _condition.name = value.isNotEmpty ? value : null;
            },
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
