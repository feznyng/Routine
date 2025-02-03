import 'package:flutter/material.dart';
import 'block_apps_dialog.dart';
import 'block_sites_dialog.dart';

class BlockGroupEditor extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final Function(List<String>, List<String>) onSave;
  final bool blockSelected;
  final Function(bool) onBlockModeChanged;
  final bool showBlockMode;

  const BlockGroupEditor({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
    required this.blockSelected,
    required this.onBlockModeChanged,
    this.showBlockMode = true,
  });

  @override
  State<BlockGroupEditor> createState() => _BlockGroupEditorState();
}

class _BlockGroupEditorState extends State<BlockGroupEditor> {
  late List<String> _selectedApps;
  late List<String> _selectedSites;
  late bool _blockSelected;

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
    _selectedSites = List.from(widget.selectedSites);
    _blockSelected = widget.blockSelected;
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

  String _getAppSubtitle() {
    if (_selectedApps.isEmpty) {
      return _blockSelected
          ? 'No applications blocked'
          : 'All applications blocked';
    }
    return _blockSelected
        ? '${_selectedApps.length} applications blocked'
        : '${_selectedApps.length} applications allowed';
  }

  String _getSiteSubtitle() {
    if (_selectedSites.isEmpty) {
      return _blockSelected
          ? 'No sites blocked'
          : 'All sites blocked';
    }
    return _blockSelected
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showBlockMode) ...[
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
                  selected: {_blockSelected},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _blockSelected = newSelection.first;
                    });
                    widget.onBlockModeChanged(_blockSelected);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        _buildBlockButton(
          title: 'Applications',
          subtitle: _getAppSubtitle(),
          icon: Icons.apps,
          onPressed: _openAppsDialog,
        ),
        const SizedBox(height: 5),
        _buildBlockButton(
          title: 'Sites',
          subtitle: _getSiteSubtitle(),
          icon: Icons.language,
          onPressed: _openSitesDialog,
        ),
      ],
    );
  }
}