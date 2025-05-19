import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Routine/setup.dart';

class AppSiteSelectorPage extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final List<String>? selectedCategories;
  final Function(List<String>, List<String>, List<String>?) onSave;
  final bool inLockdown;
  final bool blockSelected;

  const AppSiteSelectorPage({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
    required this.inLockdown,
    required this.blockSelected,
    this.selectedCategories,
  });

  @override
  State<AppSiteSelectorPage> createState() => _AppSiteSelectorPageState();
}

class _AppSiteSelectorPageState extends State<AppSiteSelectorPage> {
  List<String> _currentApps = [];
  List<String> _currentSites = [];
  List<String>? _currentCategories = [];
  bool _isValidChange = true;

  bool _canSaveChanges(List<String> newApps, List<String> newSites) {
    if (!widget.inLockdown) return true;

    final removedApps = widget.selectedApps.where((app) => !newApps.contains(app)).toList();
    final addedApps = newApps.where((app) => !widget.selectedApps.contains(app)).toList();
    final removedSites = widget.selectedSites.where((site) => !newSites.contains(site)).toList();
    final addedSites = newSites.where((site) => !widget.selectedSites.contains(site)).toList();

    // For block lists (blockSelected = true):
    // - Users can add new items but cannot remove existing items
    // For allow lists (blockSelected = false):
    // - Users can remove items but cannot add new items
    final hasRemovedBlockedItems = removedApps.isNotEmpty || removedSites.isNotEmpty;
    final hasAddedAllowedItems = addedApps.isNotEmpty || addedSites.isNotEmpty;

    // For block lists (blockSelected = true):
    // - Users can add new items but cannot remove existing items
    if (widget.blockSelected && hasRemovedBlockedItems) {
      return false;
    }

    // For allow lists (blockSelected = false):
    // - Users can remove items but cannot add new items
    if (!widget.blockSelected && hasAddedAllowedItems) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _currentApps = List.from(widget.selectedApps);
    _currentSites = List.from(widget.selectedSites);
    _currentCategories = widget.selectedCategories != null
        ? List.from(widget.selectedCategories!)
        : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: !_isValidChange ? null : () async {
              widget.onSave(_currentApps, _currentSites, _currentCategories);
            },
            child: const Text('Done'),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (widget.inLockdown) ...[            
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.blockSelected
                        ? 'Strict mode is active. You can add new items but cannot remove existing items from this block list.'
                        : 'Strict mode is active. You can remove items but cannot add new items to this allow list.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: AppSiteSelector(
              selectedApps: _currentApps,
              selectedSites: _currentSites,
              selectedCategories: _currentCategories,
              onSelectionChanged: (apps, sites, categoryTokens) {
                final isValid = _canSaveChanges(apps, sites);
                setState(() {
                  _currentApps = apps;
                  _currentSites = sites;
                  _currentCategories = categoryTokens;
                  _isValidChange = isValid;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AppSiteSelector extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final List<String>? selectedCategories;
  final Function(List<String>, List<String>, List<String>?) onSelectionChanged;

  const AppSiteSelector({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    this.selectedCategories,
    required this.onSelectionChanged,
  });

  @override
  State<AppSiteSelector> createState() => _AppSiteSelectorState();
}

class _AppSiteSelectorState extends State<AppSiteSelector> {
  MethodChannel? _channel;
  int? _viewId;

  @override
  void dispose() {
    if (_viewId != null) {
      // Don't wait for the result since the channel might be gone
      _channel?.invokeMethod('dispose').catchError((_) {});
      _channel?.setMethodCallHandler(null);
      _channel = null;
      _viewId = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: UiKitView(
        viewType: 'app_site_selector',
        creationParams: {
          'apps': widget.selectedApps,
          'sites': widget.selectedSites,
          'categories': widget.selectedCategories,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }

  void _onPlatformViewCreated(int id) {
    _viewId = id;
    _channel = MethodChannel('app_site_selector_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (_viewId == null) return;
    switch (call.method) {
      case 'onSelectionChanged':
        final selectedApps = List<String>.from(call.arguments['apps'] ?? []);
        final selectedSites = List<String>.from(call.arguments['sites'] ?? []);
        final selectedCategories = call.arguments['categories'] != null 
            ? List<String>.from(call.arguments['categories']) 
            : null;
        widget.onSelectionChanged(selectedApps, selectedSites, selectedCategories);
        break;
      default:
        logger.e('Unhandled method ${call.method}');
    }
  }
}
