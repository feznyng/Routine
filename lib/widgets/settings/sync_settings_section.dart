import 'package:Routine/services/sync_service.dart';
import 'package:flutter/material.dart';

class SyncSettingsSection extends StatelessWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Sync'),
        leading: const Icon(Icons.sync),
        subtitle: const Text('Perform a full synchronization with the server'),
        trailing: ElevatedButton(
          onPressed: () {
            // Schedule a full sync job
            SyncService().addJob(SyncJob(remote: false, full: true));
          },
          child: const Text('Full Sync'),
        ),
      ),
    );
  }
}
