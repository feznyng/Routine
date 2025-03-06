import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import '../services/desktop_service.dart';

class BlockAppsDialog extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedCategories;

  const BlockAppsDialog({
    super.key,
    required this.selectedApps,
    required this.selectedCategories,
  });

  @override
  State<BlockAppsDialog> createState() => _BlockAppsDialogState();
}

class _BlockAppsDialogState extends State<BlockAppsDialog> with SingleTickerProviderStateMixin {
  late List<String> _selectedApps;
  late List<String> _selectedCategories;
  List<InstalledApplication> _availableApps = [];
  bool _isLoadingApps = true;
  String _appSearchQuery = '';
  String _folderSearchQuery = '';
  final TextEditingController _appSearchController = TextEditingController();
  final TextEditingController _folderSearchController = TextEditingController();
  late TabController _tabController;
  final bool _showFoldersTab = !Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
    _selectedCategories = List.from(widget.selectedCategories);
    _tabController = TabController(
      length: _showFoldersTab ? 2 : 1, 
      vsync: this
    );
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appSearchController.dispose();
    _folderSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoadingApps = true;
    });

    final List<InstalledApplication> apps = await DesktopService.getInstalledApplications();
    setState(() {
      _availableApps = apps;
      _isLoadingApps = false;
    });
  }

  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a folder to block',
    );

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      setState(() {
        if (!_selectedCategories.contains(selectedDirectory)) {
          _selectedCategories.add(selectedDirectory);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Blocked Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_showFoldersTab)
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Applications'),
                  Tab(text: 'Folders'),
                ],
              ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: _showFoldersTab 
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        // Applications Tab
                        _buildApplicationsTab(),
                        
                        // Folders Tab
                        _buildFoldersTab(),
                      ],
                    )
                  : _buildApplicationsTab(),
              ),
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
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'apps': _selectedApps,
                      'categories': _selectedCategories,
                    });
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsTab() {
    return Column(
      children: [
        TextField(
          controller: _appSearchController,
          decoration: const InputDecoration(
            hintText: 'Search applications...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _appSearchQuery = value;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_isLoadingApps)
          const Center(child: CircularProgressIndicator())
        else if (_availableApps.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No applications found', 
              style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              shrinkWrap: true,
              itemCount: _availableApps.length,
              itemBuilder: (context, index) {
                final app = _availableApps[index];
                final appName = app.name;
                if (_appSearchQuery.isNotEmpty && 
                    !appName.toLowerCase().contains(_appSearchQuery.toLowerCase())) {
                  return const SizedBox.shrink();
                }
                return CheckboxListTile(
                  title: Text(appName),
                  subtitle: Text(app.filePath, 
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _selectedApps.contains(app.filePath),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedApps.add(app.filePath);
                      } else {
                        _selectedApps.remove(app.filePath);
                      }
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFoldersTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _folderSearchController,
                decoration: const InputDecoration(
                  hintText: 'Search folders...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _folderSearchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _selectFolder,
              icon: const Icon(Icons.create_new_folder),
              label: const Text('Add Folder'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedCategories.isEmpty
            ? const Center(
                child: Text('No folders selected', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(4),
                shrinkWrap: true,
                itemCount: _selectedCategories.length,
                itemBuilder: (context, index) {
                  final folder = _selectedCategories[index];
                  if (_folderSearchQuery.isNotEmpty && 
                      !folder.toLowerCase().contains(_folderSearchQuery.toLowerCase())) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _selectedCategories.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
