import 'package:flutter/material.dart';

class BlockSitesPage extends StatefulWidget {
  final List<String> selectedSites;
  final Function(List<String>) onSave;

  const BlockSitesPage({
    super.key,
    required this.selectedSites,
    required this.onSave,
  });

  @override
  State<BlockSitesPage> createState() => _BlockSitesPageState();
}

class _BlockSitesPageState extends State<BlockSitesPage> {
  late List<String> _selectedSites;
  final TextEditingController _siteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSites = List.from(widget.selectedSites);
  }

  @override
  void dispose() {
    _siteController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
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
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Filter sites based on search query
    final filteredSites = _searchQuery.isEmpty
        ? _selectedSites
        : _selectedSites.where((site) => 
            site.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Sites'),
        actions: [
          TextButton(
            onPressed: () => widget.onSave(_selectedSites),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              focusNode: _focusNode,
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
            const SizedBox(height: 16),
            
            // Search field
            if (_selectedSites.isNotEmpty) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search sites',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            if (_selectedSites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No sites blocked', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else if (filteredSites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No sites match your search', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: filteredSites.map((site) => ListTile(
                      title: Text(site),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            _selectedSites.remove(site);
                          });
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
