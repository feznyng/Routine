import 'dart:async';

import 'package:flutter/material.dart';
import 'block_group_editor.dart';
import 'block_groups_page.dart';
import '../group.dart';

class BlockGroupPage extends StatefulWidget {
  final Group? selectedGroup;
  final Function(Group) onSave;
  final VoidCallback onBack;
  final String deviceId;

  const BlockGroupPage({
    super.key,
    this.selectedGroup,
    required this.onSave,
    required this.onBack,
    required this.deviceId,
  });

  @override
  State<BlockGroupPage> createState() => _BlockGroupPageState();
}

class _BlockGroupPageState extends State<BlockGroupPage> {
  late List<Group> _blockGroups;
  late Group _selectedGroup;
  late StreamSubscription<List<Group>> _subscription;
  String? _lastCreatedGroupId;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.selectedGroup ?? Group();
    _blockGroups = [];

    _subscription = Group.watchAllNamed(deviceId: widget.deviceId).listen((event) {
      if (mounted) {
        setState(() {
          // Find any new groups that weren't in the previous list
          final newGroups = event.where((group) => 
            !_blockGroups.any((oldGroup) => oldGroup.id == group.id));
          
          _blockGroups = event;
          
          // If we found new groups, select the last one created
          if (newGroups.isNotEmpty) {
            final lastNewGroup = newGroups.last;
            _lastCreatedGroupId = lastNewGroup.id;
            _selectedGroup = lastNewGroup;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();  // Cancel the subscription when disposing
    super.dispose();
  }

  Future<void> _navigateToManageGroups() async {
    final Group? result = await Navigator.of(context).push<Group>(
      MaterialPageRoute<Group>(
        builder: (context) => const BlockGroupsPage(),
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _selectedGroup = result;
      });
    }
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
            child: const Text('Done'),
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
                      // Select the last created group when the dropdown is built
                      key: ValueKey(_lastCreatedGroupId), // Force rebuild when new group is created
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
                  blockSelected: !_selectedGroup.allow,
                  onBlockModeChanged: (value) {
                    print('Block mode changed: $value');
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