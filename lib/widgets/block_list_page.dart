import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class BlockListPage extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final Function(List<String>, List<String>) onSave;

  const BlockListPage({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
  });

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  late List<String> _selectedApps;
  late List<String> _selectedSites;
  final TextEditingController _siteController = TextEditingController();
  List<String> _availableApps = [];
  bool _isLoadingApps = true;
  String _appSearchQuery = '';
  final TextEditingController _appSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
    _selectedSites = List.from(widget.selectedSites);
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoadingApps = true;
    });

    final List<String> apps = [];
    final Directory applicationsDir = Directory('/Applications');
    
    try {
      await for (final FileSystemEntity entity in applicationsDir.list()) {
        if (entity.path.endsWith('.app')) {
          apps.add(entity.path);
        }
      }

      // Sort apps alphabetically
      apps.sort();

      if (!mounted) return;
      setState(() {
        _availableApps = apps;
        _isLoadingApps = false;
      });
    } catch (e) {
      debugPrint('Error loading applications: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingApps = false;
      });
    }
  }

  void _addSite(String site) {
    if (site.isEmpty) return;
    
    // Basic URL cleanup
    site = site.toLowerCase().trim();
    if (site.startsWith('http://')) site = site.substring(7);
    if (site.startsWith('https://')) site = site.substring(8);
    if (site.startsWith('www.')) site = site.substring(4);
    
    setState(() {
      if (!_selectedSites.contains(site)) {
        _selectedSites.add(site);
      }
    });
    _siteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Sites
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blocked Sites',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _siteController,
                        decoration: InputDecoration(
                          hintText: 'Enter a website (e.g., facebook.com)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addSite(_siteController.text),
                          ),
                        ),
                        onSubmitted: _addSite,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedSites.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No sites blocked', 
                            style: TextStyle(fontStyle: FontStyle.italic)),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Material(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(4),
                            child: ListView(
                              padding: const EdgeInsets.all(8),
                              shrinkWrap: true,
                              children: _selectedSites.map((site) => Chip(
                                label: Text(site),
                                onDeleted: () {
                                  setState(() {
                                    _selectedSites.remove(site);
                                  });
                                },
                              )).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Right side - Apps
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blocked Applications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 8),
                      if (_isLoadingApps)
                        const Center(child: CircularProgressIndicator())
                      else if (_availableApps.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No applications found', 
                            style: TextStyle(fontStyle: FontStyle.italic)),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: Material(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(4),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(4),
                              shrinkWrap: true,
                              itemCount: _availableApps.length,
                              itemBuilder: (context, index) {
                                final app = _availableApps[index];
                                final appName = path.basenameWithoutExtension(app);
                                if (_appSearchQuery.isNotEmpty && 
                                    !appName.toLowerCase().contains(_appSearchQuery.toLowerCase())) {
                                  return const SizedBox.shrink();
                                }
                                
                                return CheckboxListTile(
                                  title: Text(appName),
                                  value: _selectedApps.contains(app),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedApps.add(app);
                                      } else {
                                        _selectedApps.remove(app);
                                      }
                                    });
                                  },
                                  dense: true,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onSave(_selectedApps, _selectedSites);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _siteController.dispose();
    _appSearchController.dispose();
    super.dispose();
  }
}
