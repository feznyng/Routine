import 'package:flutter/material.dart';
import 'block_group_editor.dart';
import 'block_groups_page.dart';
import '../group.dart';

class BlockGroupPage extends StatefulWidget {
  final Group selectedGroup;
  final Function(Group) onSave;
  final VoidCallback onBack;

  const BlockGroupPage({
    super.key,
    required this.selectedGroup,
    required this.onSave,
    required this.onBack,
  });

  @override
  State<BlockGroupPage> createState() => _BlockGroupPageState();
}

class _BlockGroupPageState extends State<BlockGroupPage> {
  late List<Group> _blockGroups;
  late Group _selectedGroup;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.selectedGroup;

    Group.watchAllNamed().listen((event) {
      setState(() {
        _blockGroups = event;
      });
    });
  }

  Future<void> _navigateToManageGroups() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BlockGroupsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usingNamedGroup = _blockGroups.any((group) => group.id == _selectedGroup.id);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onBack();
          },
        ),
        title: const Text('Block Group'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(_selectedGroup);
              widget.onBack();
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group selection row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _blockGroups.any((group) => group.id == _selectedGroup.id) ? _selectedGroup.id : null,
                      decoration: const InputDecoration(
                        labelText: 'Block Group',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Custom'),
                        ),
                        ..._blockGroups.map((blockGroup) {
                          return DropdownMenuItem<String>(
                            value: blockGroup.id,
                            child: Text(blockGroup.name ?? 'Unnamed List'),
                          );
                        }),
                      ],
                      onChanged: (String? newId) {
                        setState(() {
                          _selectedGroup = newId == null ? Group() : _blockGroups.firstWhere((group) => group.id == newId);
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _navigateToManageGroups,
                    tooltip: 'Edit Groups',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (usingNamedGroup)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'This routine will use the selected block list.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!usingNamedGroup) 
                BlockGroupEditor(
                  selectedApps: _selectedGroup.apps,
                  selectedSites: _selectedGroup.sites,
                  blockSelected: _selectedGroup.allow,
                  onBlockModeChanged: (value) {
                    setState(() {
                      _selectedGroup.allow = value;
                    });
                  },
                  onSave: (apps, sites) {
                    setState(() {
                      _selectedGroup.apps = apps;
                      _selectedGroup.sites = sites;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}