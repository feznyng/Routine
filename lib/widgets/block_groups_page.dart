import 'package:flutter/material.dart';
import '../group.dart';
import '../manager.dart';
import 'block_group_editor.dart';
import 'package:uuid/uuid.dart';

class BlockGroupsPage extends StatelessWidget {
  const BlockGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = Manager();
    final groups = manager.namedBlockGroups.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Groups'),
      ),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return ListTile(
            title: Text(group.name ?? 'Unnamed Group'),
            subtitle: Text(
              '${group.apps.length} apps, ${group.sites.length} sites',
            ),
            onTap: () => _editGroup(context, group),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createGroup(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editGroup(BuildContext context, Group group) async {
    final manager = Manager();
    List<String> apps = List.from(group.apps);
    List<String> sites = List.from(group.sites);
    bool blockMode = group.allow;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name ?? 'Edit Group'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: group.name),
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Update name in manager
                    manager.upsertBlockGroup(
                      group.copyWith(name: value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlockGroupEditor(
                  selectedApps: apps,
                  selectedSites: sites,
                  blockSelected: !blockMode,
                  onBlockModeChanged: (value) {
                    blockMode = !value;
                    manager.upsertBlockGroup(
                      group.copyWith(allowList: blockMode),
                    );
                  },
                  onSave: (newApps, newSites) {
                    apps = newApps;
                    sites = newSites;
                    manager.upsertBlockGroup(
                      group.copyWith(
                        apps: newApps,
                        sites: newSites,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              manager.removeBlockGroup(group.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    final manager = Manager();
    String? name;
    List<String> apps = [];
    List<String> sites = [];
    bool blockMode = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Block Group'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                BlockGroupEditor(
                  selectedApps: apps,
                  selectedSites: sites,
                  blockSelected: blockMode,
                  onBlockModeChanged: (value) => blockMode = value,
                  onSave: (newApps, newSites) {
                    apps = newApps;
                    sites = newSites;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (name != null && name!.isNotEmpty) {
                manager.upsertBlockGroup(Group(
                  id: Uuid().v4(),
                  name: name,
                  deviceId: Manager().thisDevice.id,
                  apps: apps,
                  sites: sites,
                  allowList: !blockMode,
                ));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
