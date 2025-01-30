import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class BlockAppsDialog extends StatefulWidget {
  final List<String> selectedApps;

  const BlockAppsDialog({
    super.key,
    required this.selectedApps,
  });

  @override
  State<BlockAppsDialog> createState() => _BlockAppsDialogState();
}

class _BlockAppsDialogState extends State<BlockAppsDialog> {
  late List<String> _selectedApps;
  List<String> _availableApps = [];
  bool _isLoadingApps = true;
  String _appSearchQuery = '';
  final TextEditingController _appSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
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
                  'Blocked Applications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
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
            else if (_availableApps.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No applications found', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
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
                        );
                      },
                    ),
                  ),
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
                  onPressed: () => Navigator.of(context).pop(_selectedApps),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
