import 'package:flutter/material.dart';
import '../manager.dart';
import '../group.dart';
import 'block_list_page.dart';
import 'package:uuid/uuid.dart';

class BlockListsDialog extends StatefulWidget {
  const BlockListsDialog({super.key});

  @override
  State<BlockListsDialog> createState() => _BlockListsDialogState();
}

class _BlockListsDialogState extends State<BlockListsDialog> {
  final _nameController = TextEditingController();
  Group? _editingList;

  void _createNewList() {
    setState(() {
      _editingList = null;
      _nameController.clear();
    });
    _showBlockListEditor();
  }

  void _editList(Group list) {
    setState(() {
      _editingList = list;
      _nameController.text = list.name!;
    });
    _showBlockListEditor();
  }

  Future<void> _showBlockListEditor() async {
    final result = await showDialog<Group>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editingList == null ? 'Create Block Group' : 'Edit Block Group',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              BlockListPage(
                selectedApps: _editingList?.apps ?? [],
                selectedSites: _editingList?.sites ?? [],
                onSave: (apps, sites) {
                  // This will be handled when dialog is closed
                },
                blockSelected: false,
                onBlockModeChanged: (_) {},
                onBack: () {
                  Navigator.of(context).pop();
                }
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a name')),
                        );
                        return;
                      }
                      // Save the block list
                      final blockList = Group(
                        id: _editingList?.id ?? const Uuid().v4(),
                        name: _nameController.text,
                        apps: _editingList?.apps ?? [],
                        sites: _editingList?.sites ?? [],
                      );
                      Navigator.of(context).pop(blockList);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        Manager().namedBlockLists[result.id] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockLists = Manager().namedBlockLists.values.toList();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Block Groups',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: blockLists.length,
                itemBuilder: (context, index) {
                  final list = blockLists[index];
                  return ListTile(
                    title: Text(list.name!),
                    subtitle: Text(
                      '${list.apps.length} apps, ${list.sites.length} sites',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editList(list),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _createNewList,
                  child: const Text('New List'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
