import 'package:flutter/material.dart';
import '../manager.dart';
import 'block_group_editor.dart';
import 'block_groups_page.dart';

class BlockGroupPage extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final Function(List<String>, List<String>, String?) onSave;
  final bool blockSelected;
  final Function(bool) onBlockModeChanged;
  final VoidCallback onBack;
  final String? selectedBlockGroupId;

  const BlockGroupPage({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
    required this.blockSelected,
    required this.onBlockModeChanged,
    required this.onBack,
    this.selectedBlockGroupId,
  });

  @override
  State<BlockGroupPage> createState() => _BlockGroupPageState();
}

class _BlockGroupPageState extends State<BlockGroupPage> {
  late List<String> _selectedApps;
  late List<String> _selectedSites;
  late bool _blockSelected;
  late String? _selectedBlockGroupId;

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
    _selectedSites = List.from(widget.selectedSites);
    _blockSelected = widget.blockSelected;
    
    // Get the block list ID for the current device
    final currentGroupId = widget.selectedBlockGroupId;
    // Only set _selectedBlockGroupId if it's a named block list
    _selectedBlockGroupId = currentGroupId != null && 
                         Manager().namedBlockGroups.containsKey(currentGroupId)
        ? currentGroupId
        : null;
    }

  Future<void> _navigateToManageGroups() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BlockGroupsPage(),
      ),
    );
    setState(() {}); // Refresh the list after returning
  }

  @override
  Widget build(BuildContext context) {
    final manager = Manager();
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
              widget.onSave(_selectedApps, _selectedSites, _selectedBlockGroupId);
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
                      value: _selectedBlockGroupId,
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
                        ...manager.namedBlockGroups.values.map((blockGroup) {
                          return DropdownMenuItem<String>(
                            value: blockGroup.id,
                            child: Text(blockGroup.name ?? 'Unnamed List'),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newId) {
                        setState(() {
                          _selectedBlockGroupId = newId;
                          if (newId != null) {
                            final selectedList = manager.findBlockGroup(newId);
                            _selectedApps = List.from(selectedList?.apps ?? []);
                            _selectedSites = List.from(selectedList?.sites ?? []);
                            _blockSelected = !(selectedList?.allow ?? false);
                            widget.onBlockModeChanged(_blockSelected);
                          } else {
                            _selectedApps = [];
                            _selectedSites = [];
                          }
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
              if (_selectedBlockGroupId != null)
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
              if (_selectedBlockGroupId == null) 
                BlockGroupEditor(
                  selectedApps: _selectedApps,
                  selectedSites: _selectedSites,
                  blockSelected: _blockSelected,
                  onBlockModeChanged: (value) {
                    setState(() {
                      _blockSelected = value;
                    });
                    widget.onBlockModeChanged(_blockSelected);
                  },
                  onSave: (apps, sites) {
                    setState(() {
                      _selectedApps = apps;
                      _selectedSites = sites;
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
