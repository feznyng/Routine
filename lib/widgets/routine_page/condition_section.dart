import 'package:flutter/material.dart';
import '../../models/routine.dart';
import '../../models/condition.dart';
import 'condition_editors/condition_editors.dart';
import 'condition_type_utils.dart';

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

  String _getConditionSummary(Condition condition) {
    return condition.name ?? '';
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
            children: ConditionType.values
              .where((v) => ![ConditionType.health].contains(v))
              .map((type) {
              return ListTile(
                leading: Icon(ConditionTypeUtils.getIcon(type)),
                title: Text(ConditionTypeUtils.getLabel(type)),
                onTap: () {
                  Navigator.pop(context);
                  final newCondition = Condition.create(type: type);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => _ConditionEditSheet(
                      condition: newCondition,
                      onSave: (updatedCondition) {
                        routine.conditions.add(updatedCondition);
                        onChanged();
                        Navigator.pop(context);
                      },
                      onDelete: () {
                        Navigator.pop(context);
                      },
                    ),
                  );
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
              const SizedBox(height: 16),
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
                      leading: Icon(ConditionTypeUtils.getIcon(condition.type)),
                      title: Text(_getConditionSummary(condition)),
                      subtitle: Text(ConditionTypeUtils.getLabel(condition.type)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: enabled ? () => _editCondition(context, condition) : null,
                    );
                  },
                ),
              TextButton.icon(
                onPressed: enabled ? () => _addCondition(context) : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Condition'),
              ),
              const Divider(),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  title: Text(
                    'Advanced',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  leading: const Icon(Icons.settings),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Completion Window',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'minus',
                                  icon: const Icon(Icons.remove),
                                  enabled: enabled && routine.completableBefore > 5,
                                ),
                                ButtonSegment(
                                  value: 'text',
                                  label: Text('${routine.completableBefore} min'),
                                ),
                                ButtonSegment(
                                  value: 'plus',
                                  icon: const Icon(Icons.add),
                                  enabled: enabled && routine.completableBefore < 120,
                                ),
                              ],
                              emptySelectionAllowed: true,
                              selected: const {},
                              onSelectionChanged: enabled ? (Set<String> selected) {
                                if (selected.first == 'minus' && routine.completableBefore > 5) {
                                  routine.completableBefore = routine.completableBefore - 10;
                                  onChanged();
                                } else if (selected.first == 'plus' && routine.completableBefore < 120) {
                                  routine.completableBefore = routine.completableBefore + 10;
                                  onChanged();
                                }
                              } : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Allows you to complete conditions a certain amount of time prior to the routine becoming active.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
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
  String? _statusMessage;
  bool _isSuccess = false;
  bool _isError = false;
  void _showStatusMessage(String message, {bool isSuccess = false, bool isError = false, bool isLoading = false}) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _isSuccess = isSuccess;
        _isError = isError;
      });
    }
  }
  void _clearStatusMessage() {
    if (mounted) {
      setState(() {
        _statusMessage = null;
        _isSuccess = false;
        _isError = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
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
      completedAt: widget.condition.lastCompletedAt,
      original: widget.condition.toJson()
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
  


  Widget _buildStatusMessage() {
    if (_statusMessage == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isSuccess ? Colors.green.withOpacity(0.1) : 
               _isError ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isSuccess ? Colors.green : 
                 _isError ? Colors.red : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : 
            _isError ? Icons.error : Icons.info,
            color: _isSuccess ? Colors.green : 
                   _isError ? Colors.red : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _isSuccess ? Colors.green.shade800 : 
                       _isError ? Colors.red.shade800 : Colors.blue.shade800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: _clearStatusMessage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
  
  Widget _buildConditionFields() {
    switch (_condition.type) {
      case ConditionType.location:
        return LocationConditionWidget(
          condition: _condition,
          latitudeController: _latitudeController,
          longitudeController: _longitudeController,
          proximityController: _proximityController,
          onStatusMessage: (message) => _showStatusMessage(message),
        );
      case ConditionType.nfc:
        return NfcConditionWidget(
          condition: _condition,
          nameController: _nameController,
          onStatusMessage: _showStatusMessage,
        );
      case ConditionType.qr:
        return QrConditionEditor(
          condition: _condition,
          nameController: _nameController,
          onStatusMessage: _showStatusMessage,
        );
      case ConditionType.health:
        return HealthConditionWidget(
          condition: _condition,
          activityTypeController: _activityTypeController,
          activityAmtController: _activityAmtController,
        );
      case ConditionType.todo:
        return const TodoConditionWidget();
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
                  Icon(ConditionTypeUtils.getIcon(_condition.type)),
                  const SizedBox(width: 8),
                  Text(
                    'Edit ${ConditionTypeUtils.getLabel(_condition.type)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
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
              _condition = Condition(
                id: _condition.id,
                type: _condition.type,
                latitude: _condition.latitude,
                longitude: _condition.longitude,
                proximity: _condition.proximity,
                nfcQrCode: _condition.nfcQrCode,
                activityType: _condition.activityType,
                activityAmt: _condition.activityAmt,
                name: value.isNotEmpty ? value : null,
                completedAt: _condition.lastCompletedAt,
                original: _condition.toJson(),
              );
              setState(() {});
            },
          ),
          _buildStatusMessage(),
          const SizedBox(height: 16),
          _buildConditionFields(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final trimmedName = _nameController.text.trim();
                  if (trimmedName.isEmpty) {
                    _showStatusMessage('Please enter a name for this condition', isError: true);
                    return;
                  }
                  _condition.name = trimmedName;
                  widget.onSave(_condition);
                },
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
