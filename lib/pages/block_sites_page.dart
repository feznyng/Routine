import 'package:flutter/material.dart';
import '../constants.dart';

class BlockSitesPage extends StatefulWidget {
  final List<String> selectedSites;
  final Function(List<String>) onSave;
  final bool inLockdown;
  final bool blockSelected;

  const BlockSitesPage({
    super.key,
    required this.selectedSites,
    required this.onSave,
    required this.inLockdown,
    required this.blockSelected,
  });

  @override
  State<BlockSitesPage> createState() => _BlockSitesPageState();
}

class _BlockSitesPageState extends State<BlockSitesPage> {
  late List<String> _selectedSites;
  final TextEditingController _siteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selection Limit Reached'),
        content: Text('You can select a maximum of $kMaxBlockedItems sites. Please remove some sites before adding more.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addSite(String site) {
    if (site.isEmpty) return;
    
    // Check lockdown restrictions
    if (widget.inLockdown && !widget.blockSelected) {
      // Cannot add sites in allow list lockdown
      return;
    }
    
    // Check the limit before adding
    if (_selectedSites.length >= kMaxBlockedItems) {
      _showLimitDialog();
      return;
    }
    
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Blocked Sites'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(_selectedSites);
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
            if (widget.inLockdown)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Strict Mode Active',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.blockSelected 
                              ? 'You can add new websites but cannot remove existing ones.'
                              : 'You can remove websites but cannot add new ones.',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
            
            if (_selectedSites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No sites blocked', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else if (_selectedSites.isEmpty)
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
                    children: _selectedSites.map((site) => ListTile(
                      title: Text(site),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.inLockdown && widget.blockSelected 
                          ? null // Disable removal in block list lockdown
                          : () {
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
