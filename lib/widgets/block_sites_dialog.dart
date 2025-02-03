import 'package:flutter/material.dart';

class BlockSitesDialog extends StatefulWidget {
  final List<String> selectedSites;

  const BlockSitesDialog({
    super.key,
    required this.selectedSites,
  });

  @override
  State<BlockSitesDialog> createState() => _BlockSitesDialogState();
}

class _BlockSitesDialogState extends State<BlockSitesDialog> {
  late List<String> _selectedSites;
  final TextEditingController _siteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedSites = List.from(widget.selectedSites);
  }

  @override
  void dispose() {
    _siteController.dispose();
    _focusNode.dispose();
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
                  'Blocked Sites',
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
            if (_selectedSites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No sites blocked', 
                  style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
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
                    Navigator.of(context).pop(_selectedSites);
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
}
