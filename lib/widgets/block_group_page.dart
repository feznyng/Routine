import 'package:flutter/material.dart';
import 'block_apps_dialog.dart';
import 'block_sites_dialog.dart';
import '../manager.dart';

class BlockListPage extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final Function(List<String>, List<String>) onSave;
  final bool blockSelected;
  final Function(bool) onBlockModeChanged;
  final VoidCallback onBack;

  const BlockListPage({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
    required this.blockSelected,
    required this.onBlockModeChanged,
    required this.onBack,
  });

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  late List<String> _selectedApps;
  late List<String> _selectedSites;
  String? _selectedBlockListId; // Track selected block list ID

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
    _selectedSites = List.from(widget.selectedSites);
  }

  Future<void> _openAppsDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => BlockAppsDialog(selectedApps: _selectedApps),
    );

    if (result != null) {
      setState(() {
        _selectedApps = result;
      });
      widget.onSave(_selectedApps, _selectedSites);
    }
  }

  Future<void> _openSitesDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => BlockSitesDialog(selectedSites: _selectedSites),
    );

    if (result != null) {
      setState(() {
        _selectedSites = result;
      });
      widget.onSave(_selectedApps, _selectedSites);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = Manager();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onSave(_selectedApps, _selectedSites);
            widget.onBack();
          },
        ),
        title: const Text('Block Group'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown for block list selection
              DropdownButtonFormField<String>(
                value: _selectedBlockListId,
                decoration: const InputDecoration(
                  labelText: 'Block Group',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...manager.namedBlockLists.values.map((blockList) {
                    return DropdownMenuItem<String>(
                      value: blockList.id,
                      child: Text(blockList.name ?? 'Unnamed List'),
                    );
                  }).toList(),
                ],
                onChanged: (String? newId) {
                  setState(() {
                    _selectedBlockListId = newId;
                    if (newId != null) {
                      final selectedList = manager.findBlockList(newId);
                      _selectedApps = List.from(selectedList?.apps ?? []);
                      _selectedSites = List.from(selectedList?.sites ?? []);
                    } else {
                      _selectedApps = [];
                      _selectedSites = [];
                    }
                  });
                  widget.onSave(_selectedApps, _selectedSites);
                },
              ),
              const SizedBox(height: 24),
              if (_selectedBlockListId != null)
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
              if (_selectedBlockListId == null) 
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Block'),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Allow'),
                          ),
                        ],
                        selected: {widget.blockSelected},
                        onSelectionChanged: (Set<bool> newSelection) {
                          widget.onBlockModeChanged(newSelection.first);
                        },
                      ),
                    ],
                  ),
                ),
              if (_selectedBlockListId == null) 
                const SizedBox(height: 10),
              if (_selectedBlockListId == null) 
                _buildBlockButton(
                  title: 'Applications',
                  subtitle: _getAppSubtitle(),
                  icon: Icons.apps,
                  onPressed: _openAppsDialog,
                ),
              if (_selectedBlockListId == null) 
                const SizedBox(height: 5),
              if (_selectedBlockListId == null) 
                _buildBlockButton(
                  title: 'Sites',
                  subtitle: _getSiteSubtitle(),
                  icon: Icons.language,
                  onPressed: _openSitesDialog,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppSubtitle() {
    if (_selectedApps.isEmpty) {
      return widget.blockSelected
          ? 'No applications blocked'
          : 'All applications blocked';
    }
    return widget.blockSelected
        ? '${_selectedApps.length} applications blocked'
        : '${_selectedApps.length} applications allowed';
  }

  String _getSiteSubtitle() {
    if (_selectedSites.isEmpty) {
      return widget.blockSelected
          ? 'No sites blocked'
          : 'All sites blocked';
    }
    return widget.blockSelected
        ? '${_selectedSites.length} sites blocked'
        : '${_selectedSites.length} sites allowed';
  }

  Widget _buildBlockButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Card(
      color: enabled ? null : Theme.of(context).disabledColor.withOpacity(0.1),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: enabled 
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
