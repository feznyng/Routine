import 'package:Routine/services/sync_service.dart';
import 'package:flutter/material.dart';

class SyncSettingsSection extends StatefulWidget {
  const SyncSettingsSection({super.key});

  @override
  State<SyncSettingsSection> createState() => _SyncSettingsSectionState();
}

class _SyncSettingsSectionState extends State<SyncSettingsSection> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      await SyncService().sync(full: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Sync'),
        leading: const Icon(Icons.sync),
        subtitle: const Text('Perform a full sync between your devices.'),
        trailing: _isSyncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
              ),
            )
          : TextButton(
              onPressed: _performSync,
              child: const Text('Full Sync'),
            ),
      ),
    );
  }
}
