import 'package:flutter/material.dart';
import '../group.dart';
import 'edit_block_group_page.dart';

class BlockGroupsPage extends StatefulWidget {
  const BlockGroupsPage({super.key});

  @override
  State<BlockGroupsPage> createState() => _BlockGroupsPageState();
}

class _BlockGroupsPageState extends State<BlockGroupsPage> {
  List<Group> groups = [];

  @override
  void initState() {
    super.initState();
    Group.watchAllNamed().listen((value) => setState(() => groups = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Groups'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditBlockGroupPage(
          group: group,
          onSave: (updatedGroup) {
            updatedGroup.save();
            Navigator.of(context).pop();
            setState(() {});
          },
          onDelete: group.saved ? () {
            group.delete();
            Navigator.of(context).pop();
            setState(() {});
          } : null,
        ),
      ),
    );
  }
}