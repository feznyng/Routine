import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import '../services/desktop_service.dart';
import '../constants.dart';

class BlockAppsPage extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedCategories;
  final Function(Map<String, List<String>>) onSave;

  const BlockAppsPage({
    super.key,
    required this.selectedApps,
    required this.selectedCategories,
    required this.onSave,
  });

  @override
  State<BlockAppsPage> createState() => _BlockAppsPageState();
}

class _BlockAppsPageState extends State<BlockAppsPage> with SingleTickerProviderStateMixin {
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
    if (_selectedCategories.length >= kMaxBlockedItems) {
      _showLimitDialog('folders');
      return;
    }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Items'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave({
                'apps': _selectedApps,
                'categories': _selectedCategories,
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showFoldersTab)
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Applications'),
                  Tab(text: 'Folders'),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(
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
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsTab() {
    // Create two lists: one for selected apps and one for unselected apps
    List<InstalledApplication> selectedAppObjects = [];
    List<InstalledApplication> unselectedAppObjects = [];
    
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
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadApplications,
                  tooltip: 'Refresh application list',
                ),
              ],
            ),
          ),
        
        // Search field and custom app button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _appSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Search applications',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _appSearchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _pickCustomApp,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Select'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
        
        // Loading indicator or app lists
        Expanded(
          child: _isLoadingApps
            ? const Center(child: CircularProgressIndicator())
            : _buildAppLists(selectedAppObjects, unselectedAppObjects),
        ),
      ],
    );
  }

  void _showLimitDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selection Limit Reached'),
        content: Text('You can select a maximum of $kMaxBlockedItems $type. Please remove some items before adding more.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomApp() async {
    if (_selectedApps.length >= kMaxBlockedItems) {
      _showLimitDialog('applications');
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: Platform.isWindows ? FileType.custom : FileType.any,
      allowedExtensions: Platform.isWindows ? ['exe'] : null,
      dialogTitle: 'Select an application to block',
    );
    
    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      
      setState(() {
        if (!_selectedApps.contains(filePath)) {
          _selectedApps.add(filePath);
        }
      });
    }
  }

  Widget _buildAppLists(List<InstalledApplication> selectedApps, List<InstalledApplication> unselectedApps) {
    // Filter apps based on search query
    final filteredSelectedApps = _appSearchQuery.isEmpty
        ? selectedApps
        : selectedApps.where((app) {
            final name = (app.displayName ?? app.name).toLowerCase();
            return name.contains(_appSearchQuery);
          }).toList();
          
    final filteredUnselectedApps = _appSearchQuery.isEmpty
        ? unselectedApps
        : unselectedApps.where((app) {
            final name = (app.displayName ?? app.name).toLowerCase();
            return name.contains(_appSearchQuery);
          }).toList();
    
    // If nothing matches the search query
    if (filteredSelectedApps.isEmpty && filteredUnselectedApps.isEmpty) {
      return const Center(
        child: Text('No applications found matching your search'),
      );
    }
    
    return ListView(
      children: [
        // Selected apps section
        if (filteredSelectedApps.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Selected Applications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...filteredSelectedApps.map((app) => _buildAppTile(app, true)),
          const Divider(),
        ],
        
        // Unselected apps section
        if (filteredUnselectedApps.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Available Applications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...filteredUnselectedApps.map((app) => _buildAppTile(app, false)),
        ],
      ],
    );
  }

  Widget _buildAppTile(InstalledApplication app, bool isSelected) {
    return ListTile(
      leading: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.circle_outlined),
      title: Text(app.displayName ?? app.name),
      subtitle: Text(
        app.filePath,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSelected 
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  _selectedApps.remove(app.filePath);
                });
              },
            )
          : null,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedApps.remove(app.filePath);
          } else if (_selectedApps.length >= kMaxBlockedItems) {
            _showLimitDialog('applications');
          } else {
            _selectedApps.add(app.filePath);
          }
        });
      },
    );
  }

  Widget _buildFoldersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search field and add folder button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _folderSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Search folders',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _folderSearchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _selectFolder,
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Select'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
        
        // Selected folders list
        Expanded(
          child: _buildFoldersList(),
        ),
      ],
    );
  }

  Widget _buildFoldersList() {
    // Filter folders based on search query
    final filteredFolders = _folderSearchQuery.isEmpty
        ? _selectedCategories
        : _selectedCategories.where((folder) => 
            folder.toLowerCase().contains(_folderSearchQuery)).toList();
    
    if (filteredFolders.isEmpty) {
      return Center(
        child: Text(
          _selectedCategories.isEmpty
              ? 'No folders selected'
              : 'No folders match your search',
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: filteredFolders.length,
      itemBuilder: (context, index) {
        final folder = filteredFolders[index];
        return ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder.split(Platform.pathSeparator).last),
          subtitle: Text(
            folder,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _selectedCategories.remove(folder);
              });
            },
          ),
        );
      },
    );
  }
}
