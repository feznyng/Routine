import 'package:flutter/material.dart';
import 'block_apps_dialog.dart';
import 'block_sites_dialog.dart';

class BlockListPage extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final Function(List<String>, List<String>) onSave;
  final bool blockSelected;
  final Function(bool) onBlockModeChanged;

  const BlockListPage({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
    required this.blockSelected,
    required this.onBlockModeChanged,
  });

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  late List<String> _selectedApps;
  late List<String> _selectedSites;

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        label: Text('Blocklist'),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Allowlist'),
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
            const SizedBox(height: 10),
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
  }) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
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
