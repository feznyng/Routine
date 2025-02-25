import 'package:flutter/material.dart';
import '../group.dart';
import 'block_group_editor.dart';

class EditBlockGroupPage extends StatefulWidget {
  final Group group;
  final Function(Group) onSave;
  final VoidCallback? onDelete;

  const EditBlockGroupPage({
    super.key,
    required this.group,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditBlockGroupPage> createState() => _EditBlockGroupPageState();
}

class _EditBlockGroupPageState extends State<EditBlockGroupPage> {
  late Group _group;
  late final TextEditingController _nameController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _nameController = TextEditingController(text: _group.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    if (!mounted) return;

    setState(() {
      _hasChanges = _group.modified;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Block Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _hasChanges ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                controller: _nameController,
                onChanged: (value) {
                  setState(() {
                    _group.name = value;
                  });
                  _checkChanges();
                },
              ),
              const SizedBox(height: 24),
              BlockGroupEditor(
                selectedApps: _group.apps,
                selectedSites: _group.sites,
                selectedCategories: _group.categories,
                blockSelected: !_group.allow,
                onBlockModeChanged: (blockMode) {
                  setState(() {
                    _group.allow = !blockMode;
                  });
                  _checkChanges();
                },
                onSave: (apps, sites, categories) {
                  setState(() {
                    _group.apps = apps;
                    _group.sites = sites;
                    _group.categories = categories ?? [];
                  });
                  _checkChanges();
                },
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete Group',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    widget.onSave(_group);
  }
}