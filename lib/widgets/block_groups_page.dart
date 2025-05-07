import 'dart:async';

import 'package:Routine/services/strict_mode_service.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import 'edit_block_group_page.dart';

class BlockGroupsPage extends StatefulWidget {
  const BlockGroupsPage({super.key});

  @override
  State<BlockGroupsPage> createState() => _BlockGroupsPageState();
}

class _BlockGroupsPageState extends State<BlockGroupsPage> {
  List<Group> groups = [];
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Group.watchAllNamed().listen((value) {
      if (mounted) {
        setState(() => groups = value);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Groups'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return ListTile(
            title: Text(group.name ?? 'Unnamed Group'),
            subtitle: Text(
              group.allow
                  ? '${group.apps.length} apps, ${group.sites.length} sites allowed'
                  : '${group.apps.length} apps, ${group.sites.length} sites blocked',
            ),
            onTap: () => _showEditPage(context, group),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditPage(context, Group()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditPage(BuildContext context, Group group) async {
    final inLockdown = await StrictModeService().isGroupLockedDown(group.id);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditBlockGroupPage(
          group: group,
          inLockdown: inLockdown,
          onSave: (updatedGroup) {
            print('Saving group: ${updatedGroup.name}');
            updatedGroup.save();
            Navigator.of(context).pop();
            setState(() {});
            // Pop back to BlockGroupPage with the updated group
            Navigator.of(context).pop(updatedGroup);
          },
          onDelete: group.saved ? () {
            group.delete();
            setState(() {});
            Navigator.of(context).pop();
          } : null,
        ),
      ),
    );
  }
}