import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_selector/file_selector.dart';
import '../../models/routine.dart';
import '../../models/condition.dart';
import 'condition_editors/condition_editors.dart';

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
      // Safely handle the proximity which might be null
      final proximityText = condition.proximity != null ? ' (${condition.proximity!.toInt()} m)' : '';
      return '${condition.name!}$proximityText';
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
        return condition.nfcQrCode ?? 'No code set';
      case ConditionType.qr:
        return 'Scan QR code to verify';
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
            children: ConditionType.values
              .where((v) => ![ConditionType.health].contains(v))
              .map((type) {
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
  
  // Flag to track if NFC tag has been successfully written
  bool _nfcTagWritten = false;
  
  // Status message for all operations
  String? _statusMessage;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isError = false;
  
  // Show a status message in the UI
  void _showStatusMessage(String message, {bool isSuccess = false, bool isError = false, bool isLoading = false}) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _isSuccess = isSuccess;
        _isError = isError;
        _isLoading = isLoading;
      });
    }
  }
  
  // Clear the status message
  void _clearStatusMessage() {
    if (mounted) {
      setState(() {
        _statusMessage = null;
        _isSuccess = false;
        _isError = false;
        _isLoading = false;
      });
    }
  }

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
  
  /// Checks if the current platform is desktop (macOS, Windows, Linux)
  Future<bool> _isDesktopPlatform() async {
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return true;
      }
    } catch (e) {
      // If Platform is not available, we're probably on web
      return false;
    }
    return false;
  }
  
  /// Gets the downloads directory path for desktop platforms
  Future<String?> _getDownloadsPath() async {
    try {
      if (Platform.isMacOS) {
        final Directory homeDir = Directory(Platform.environment['HOME'] ?? '');
        return '${homeDir.path}/Downloads';
      } else if (Platform.isWindows) {
        final Directory homeDir = Directory(Platform.environment['USERPROFILE'] ?? '');
        return '${homeDir.path}\\Downloads';
      } else if (Platform.isLinux) {
        final Directory homeDir = Directory(Platform.environment['HOME'] ?? '');
        return '${homeDir.path}/Downloads';
      }
    } catch (e) {
      // If we can't get the downloads directory, return null
      return null;
    }
    return null;
  }
  
  /// Saves the QR code as a PNG file
  Future<void> _saveQrCode(String data) async {
    try {
      // Create QR painter
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      _showStatusMessage('Generating QR code...', isLoading: true);
      
      // Generate image data
      final imageData = await painter.toImageData(600.0);
      if (imageData == null) {
        if (context.mounted) {
          _showStatusMessage('Failed to generate QR code image', isError: true);
        }
        return;
      }
      
      // Convert to Uint8List
      final imageBytes = imageData.buffer.asUint8List();
      const String fileName = 'routine_qr_code.png';
      
      // Check if we're on desktop and should use Downloads directory
      final isDesktop = await _isDesktopPlatform();
      String? initialDirectory;
      
      if (isDesktop) {
        initialDirectory = await _getDownloadsPath();
      }
      
      // Set up file type and suggested name
      final saveLocation = await getSaveLocation(
        suggestedName: fileName,
        initialDirectory: initialDirectory,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'PNG Images',
            extensions: ['png'],
          ),
        ],
      );
      
      if (saveLocation != null) {
        // Create file and write bytes
        final file = XFile.fromData(
          imageBytes,
          mimeType: 'image/png',
          name: fileName,
        );
        
        await file.saveTo(saveLocation.path);
        
        if (context.mounted) {
          _showStatusMessage('QR code saved to: ${saveLocation.path}', isSuccess: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showStatusMessage('Error saving QR code: $e', isError: true);
      }
    }
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
          onStatusMessage: _showStatusMessage,
          onNfcTagWritten: (written) => setState(() => _nfcTagWritten = written),
        );
      case ConditionType.qr:
        return QrConditionWidget(
          condition: _condition,
          onSaveQrCode: () => _saveQrCode(_condition.data),
          isLoading: _isLoading,
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
          // Display status message if available
          _buildStatusMessage(),
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
                onPressed: (_condition.type == ConditionType.nfc && !_nfcTagWritten) 
                  ? null // Disable button if NFC condition and tag not written
                  : () => widget.onSave(_condition),
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
