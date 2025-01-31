import 'package:flutter/material.dart';
import '../group.dart';
import '../manager.dart';
import 'block_group_editor.dart';
import 'package:uuid/uuid.dart';

class EditBlockGroupPage extends StatefulWidget {
  final Group? group;
  final Function(Group) onSave;
  final VoidCallback? onDelete;

  const EditBlockGroupPage({
    super.key,
    this.group,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditBlockGroupPage> createState() => _EditBlockGroupPageState();
}

class _EditBlockGroupPageState extends State<EditBlockGroupPage> {
  late TextEditingController _nameController;
  late List<String> _selectedApps;
  late List<String> _selectedSites;
  late bool _blockSelected;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _selectedApps = List.from(widget.group?.apps ?? []);
    _selectedSites = List.from(widget.group?.sites ?? []);
    _blockSelected = !(widget.group?.allow ?? false);

    _nameController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    if (!mounted) return;

    final hasNameChange = _nameController.text != (widget.group?.name ?? '');
    final hasAppsChange = !_listEquals(_selectedApps, widget.group?.apps ?? []);
    final hasSitesChange = !_listEquals(_selectedSites, widget.group?.sites ?? []);
    final hasBlockModeChange = _blockSelected == (widget.group?.allow ?? false);

    setState(() {
      _hasChanges = hasNameChange || hasAppsChange || hasSitesChange || hasBlockModeChange;
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group == null ? 'New Block Group' : 'Edit Block Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onDelete,
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              BlockGroupEditor(
                selectedApps: _selectedApps,
                selectedSites: _selectedSites,
                blockSelected: _blockSelected,
                onBlockModeChanged: (value) {
                  setState(() {
                    _blockSelected = value;
                  });
                  _checkChanges();
                },
                onSave: (apps, sites) {
                  setState(() {
                    _selectedApps = apps;
                    _selectedSites = sites;
                  });
                  _checkChanges();
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            )
          : null,
    );
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
        ),
      );
      return;
    }

    final updatedGroup = (widget.group ?? Group(
      id: const Uuid().v4(),
      deviceId: Manager().thisDevice.id,
      name: null,
      apps: const [],
      sites: const [],
      allowList: false,
    )).copyWith(
      name: _nameController.text,
      apps: _selectedApps,
      sites: _selectedSites,
      allowList: !_blockSelected,
    );

    widget.onSave(updatedGroup);
    Navigator.of(context).pop();
  }
}
