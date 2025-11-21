import 'dart:async';
import 'package:routine_blocker/pages/edit_block_group_page.dart';
import 'package:flutter/material.dart';
import '../widgets/block_group_editor.dart';
import 'block_groups_page.dart';
import '../models/group.dart';
import '../models/device.dart';

class BlockGroupPage extends StatefulWidget {
  final Group? selectedGroup;
  final Function(Group) onSave;
  final VoidCallback onBack;
  final String deviceId;
  final bool inLockdown;

  const BlockGroupPage({
    super.key,
    this.selectedGroup,
    required this.onSave,
    required this.onBack,
    required this.deviceId,
    required this.inLockdown
  });

  @override
  State<BlockGroupPage> createState() => _BlockGroupPageState();
}

class _BlockGroupPageState extends State<BlockGroupPage> {
  late List<Group> _blockGroups;
  late Group _selectedGroup;
  late StreamSubscription<List<Group>> _subscription;
  Key _dropdownKey = UniqueKey();
  bool _isCurrentDevice = true;

  Future<void> _showNotAllowedDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        title: const Text('Modify Group'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.selectedGroup ?? Group();
    _blockGroups = [];
    Device.getCurrent().then((currDevice) {
      if (!mounted) return;
      setState(() {
        _isCurrentDevice = currDevice.id == widget.deviceId;
      });
    });

    _subscription = Group.watchAllNamed(deviceId: widget.deviceId).listen((event) {
      if (mounted) {
        setState(() {
          final newGroups = event.where((group) => 
            !_blockGroups.any((oldGroup) => oldGroup.id == group.id));
          
          _blockGroups = event;
          if (newGroups.isNotEmpty) {
            final lastNewGroup = newGroups.last;
            _selectedGroup = lastNewGroup;
          }
          if (!_isCurrentDevice && !_blockGroups.any((g) => g.id == _selectedGroup.id)) {
            if (_blockGroups.isNotEmpty) {
              _selectedGroup = _blockGroups.first;
            }
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

  Future<void> _editCurrentGroup() async {
    if (!_blockGroups.any((group) => group.id == _selectedGroup.id)) {
      return; // Don't allow editing custom groups
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditBlockGroupPage(
          group: _selectedGroup,
          onSave: (updatedGroup) async {
            await updatedGroup.save();
            if (context.mounted) {
              Navigator.of(context).pop();
              setState(() {
                _selectedGroup = updatedGroup;
              });
            }
          },
          onDelete: _selectedGroup.saved ? () async {
            await _selectedGroup.delete();
            if (context.mounted) {
              Navigator.of(context).pop();
              setState(() {
                _selectedGroup = Group(); // Reset to custom group if the selected one was deleted
              });
            }
          } : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usingNamedGroup = _blockGroups.any((group) => group.id == _selectedGroup.id);
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onBack(),
        ),
        title: const Text('Block Group'),
        actions: [
          TextButton(
            onPressed: () {
              if (!_isCurrentDevice && !usingNamedGroup) {
                _showNotAllowedDialog('Please use this device to create a custom group.');
                return;
              }
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedGroup.id == 'edit_groups' ? null : 
                             _blockGroups.any((group) => group.id == _selectedGroup.id) ? _selectedGroup.id : null,
                      key: _dropdownKey,
                      decoration: const InputDecoration(
                        labelText: 'Block Group',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          enabled: true,
                          child: const Text('Custom'),
                        ),
                        ..._blockGroups.map((blockGroup) {
                          return DropdownMenuItem<String>(
                            value: blockGroup.id,
                            child: Text(blockGroup.name ?? 'Unnamed List'),
                          );
                        }),
                        if (_blockGroups.isNotEmpty) const DropdownMenuItem<String>(
                          value: 'divider',
                          enabled: false,
                          child: Divider(),
                        ),
                        DropdownMenuItem<String>(
                          value: 'edit_groups',
                          enabled: true,
                          child: const Text('Edit Groups'),
                        ),
                      ],
                      onChanged: widget.inLockdown ? null : (String? newId) async {
                        if (newId == 'edit_groups') {
                          if (!_isCurrentDevice) {
                            await _showNotAllowedDialog('Please use this device to create or edit a group.');
                            if (mounted) {
                              setState(() {
                                _dropdownKey = UniqueKey();
                              });
                            }
                            return;
                          }
                          final Group currentGroup = _selectedGroup;
                          
                          final Group? result = await Navigator.of(context).push<Group>(
                            MaterialPageRoute<Group>(
                              builder: (context) => const BlockGroupsPage(),
                            ),
                          );
                          
                          if (result != null && mounted) {
                            setState(() {
                              _selectedGroup = result;
                              _dropdownKey = UniqueKey();
                            });
                          } else if (mounted) {
                            setState(() {
                              _selectedGroup = currentGroup;
                              _dropdownKey = UniqueKey();
                            });
                          }
                          return;
                        }
                        if (newId == null && !_isCurrentDevice) {
                          await _showNotAllowedDialog('Please use this device to create a new group.');
                          if (mounted) {
                            setState(() {
                              _dropdownKey = UniqueKey();
                            });
                          }
                          return;
                        }
                        setState(() {
                          _selectedGroup = newId == null ? Group() : _blockGroups.firstWhere((group) => group.id == newId);
                        });
                      },
                      selectedItemBuilder: (BuildContext context) {
                        return [
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
                          if (_blockGroups.isNotEmpty) const DropdownMenuItem<String>(
                            value: 'divider',
                            child: Text(''),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'edit_groups',
                            child: Text('Custom'), // Fallback to show 'Custom' if somehow selected
                          ),
                        ];
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      if (!usingNamedGroup) {
                        await _showNotAllowedDialog('Custom groups can only be created and edited on this device. Select a named group.');
                        return;
                      }
                      if (!_isCurrentDevice) {
                        await _showNotAllowedDialog('Please use this device to edit this group.');
                        return;
                      }
                      await _editCurrentGroup();
                    },
                    tooltip: 'Edit Group',
                    color: null,
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
              if (!usingNamedGroup && _isCurrentDevice) 
                BlockGroupEditor(
                  groupId: _selectedGroup.id,
                  selectedApps: _selectedGroup.apps,
                  selectedSites: _selectedGroup.sites,
                  selectedCategories: _selectedGroup.categories,
                  blockSelected: !_selectedGroup.allow,
                  onBlockModeChanged: (value) {
                    setState(() {
                      _selectedGroup.allow = !value;
                    });
                  },
                  onSave: (apps, sites, categories) {
                    setState(() {
                      _selectedGroup.apps = apps;
                      _selectedGroup.sites = sites;
                      _selectedGroup.categories = categories ?? [];
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