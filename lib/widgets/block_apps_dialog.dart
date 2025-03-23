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
    // Create two lists: one for selected apps and one for unselected apps
    List<InstalledApplication> selectedAppObjects = [];
    List<InstalledApplication> unselectedAppObjects = [];
    
    // Create a set of available app paths for quick lookup
    final Set<String> availableAppPaths = _availableApps.map((app) => app.filePath).toSet();
    
    // First, handle all selected apps (including those not in _availableApps)
    for (final appPath in _selectedApps) {
      // Check if this app is in the available apps list
      final existingApp = _availableApps.firstWhere(
        (app) => app.filePath == appPath,
        orElse: () => InstalledApplication(
          name: appPath.split('\\').last.replaceAll('.exe', ''),
          filePath: appPath,
          displayName: null,
        ),
      );
      selectedAppObjects.add(existingApp);
    }
    
    // Then, add all unselected available apps
    for (final app in _availableApps) {
      if (!_selectedApps.contains(app.filePath)) {
        unselectedAppObjects.add(app);
      }
    }
    
    // Sort both lists by name
    selectedAppObjects.sort((a, b) => (a.displayName ?? a.name).compareTo(b.displayName ?? b.name));
    unselectedAppObjects.sort((a, b) => (a.displayName ?? a.name).compareTo(b.displayName ?? b.name));
    
    return Column(
      children: [
        // Info message with refresh button - only on Windows
        if (Platform.isWindows)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Only running applications are shown. Launch the application you want to block, click Refresh, and then select it.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoadingApps ? null : _loadApplications,
                  icon: _isLoadingApps 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (Platform.isWindows)
          const SizedBox(height: 16),
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
        else if (_availableApps.isEmpty && _selectedApps.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No applications found', 
              style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(4),
              shrinkWrap: true,
              children: [
                // Display selected apps section if there are any selected apps
                if (selectedAppObjects.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Text(
                      'Selected Applications',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ...selectedAppObjects.map((app) {
                    final appName = app.displayName ?? app.name;
                    final isStaleEntry = !availableAppPaths.contains(app.filePath);
                    
                    if (_appSearchQuery.isNotEmpty && 
                        !appName.toLowerCase().contains(_appSearchQuery.toLowerCase()) &&
                        !app.filePath.toLowerCase().contains(_appSearchQuery.toLowerCase())) {
                      return const SizedBox.shrink();
                    }
                    
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(appName)),
                          if (isStaleEntry)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.orange),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Not Running',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(app.filePath, 
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: true,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == false) {
                            _selectedApps.remove(app.filePath);
                          }
                        });
                      },
                    );
                  }).toList(),
                  
                  if (unselectedAppObjects.isNotEmpty) ...[
                    const Divider(thickness: 1.5),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        'Available Applications',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ],
                
                // Display unselected apps
                if (selectedAppObjects.isEmpty && unselectedAppObjects.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Text(
                      'Available Applications',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                
                ...unselectedAppObjects.map((app) {
                  final appName = app.displayName ?? app.name;
                  if (_appSearchQuery.isNotEmpty && 
                      !appName.toLowerCase().contains(_appSearchQuery.toLowerCase()) &&
                      !app.filePath.toLowerCase().contains(_appSearchQuery.toLowerCase())) {
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
                    value: false,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedApps.add(app.filePath);
                        }
                      });
                    },
                  );
                }).toList(),
                
                // Show message when no apps are available but search is active
                if (unselectedAppObjects.isEmpty && _appSearchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No applications match "${_appSearchQuery}"',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
              ],
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
