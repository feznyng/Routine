import 'package:flutter/material.dart';
import '../../models/device.dart';

class DeviceOptionsBottomSheet extends StatefulWidget {
  final Device device;
  
  const DeviceOptionsBottomSheet({super.key, required this.device});
  
  @override
  State<DeviceOptionsBottomSheet> createState() => _DeviceOptionsBottomSheetState();
}

class _DeviceOptionsBottomSheetState extends State<DeviceOptionsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _originalName;
  bool _isLoading = false;
  bool _hasNameChanged = false;
  
  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.windows:
      case DeviceType.linux:
      case DeviceType.macos:
        return Icons.computer;
      case DeviceType.ios:
      case DeviceType.android:
        return Icons.smartphone;
      case DeviceType.ipad:
        return Icons.tablet;
    }
  }
  
  void _onNameChanged() {
    final newName = _nameController.text.trim();
    final hasChanged = newName != _originalName;
    
    if (hasChanged != _hasNameChanged) {
      setState(() {
        _hasNameChanged = hasChanged;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _originalName = widget.device.name;
    _nameController = TextEditingController(text: _originalName);
    _nameController.addListener(_onNameChanged);
  }
  
  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _updateDeviceName() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      widget.device.name = _nameController.text.trim();
      await widget.device.save();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating device: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _deleteDevice() async {
    if (widget.device.curr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete the current device')),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete ${widget.device.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    
    setState(() => _isLoading = true);
    
    try {
      await widget.device.delete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting device: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.device.curr ? 'Current Device' : 'Device Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getDeviceIcon(widget.device.type),
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.device.formattedType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.device.lastSyncStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Device name cannot be empty';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.device.curr) ...[
                TextButton(
                  onPressed: _isLoading ? null : _deleteDevice,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
              const SizedBox(width: 8),
              FilledButton(
                onPressed: (_isLoading || !_hasNameChanged) 
                    ? null 
                    : _updateDeviceName,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
