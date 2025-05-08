import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.selectedCategories,
    required this.onSave,
    required this.inLockdown,
    required this.blockSelected,
  });

  @override
  State<AppSiteSelectorPage> createState() => _AppSiteSelectorPageState();
}

class _AppSiteSelectorPageState extends State<AppSiteSelectorPage> {
  List<String> _currentApps = [];
  List<String> _currentSites = [];
  List<String>? _currentCategories = [];

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
            onPressed: () async {
              // Check if changes violate lockdown restrictions
              bool hasViolations = false;
              String violationMessage = '';
              
              if (widget.inLockdown) {
                if (widget.blockSelected) {
                  // In block list mode, can't remove items
                  if (widget.selectedApps.length > _currentApps.length ||
                      widget.selectedSites.length > _currentSites.length ||
                      (widget.selectedCategories?.length ?? 0) > (_currentCategories?.length ?? 0)) {
                    hasViolations = true;
                    violationMessage = 'Cannot remove items from a block list in lockdown';
                  }
                } else {
                  // In allow list mode, can't add items
                  if (widget.selectedApps.length < _currentApps.length ||
                      widget.selectedSites.length < _currentSites.length ||
                      (widget.selectedCategories?.length ?? 0) < (_currentCategories?.length ?? 0)) {
                    hasViolations = true;
                    violationMessage = 'Cannot add items to an allow list in lockdown';
                  }
                }
              }
              
              if (hasViolations) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(violationMessage),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }
              
              widget.onSave(_currentApps, _currentSites, _currentCategories);
            },
            child: const Text('Done'),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (widget.inLockdown)
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.blockSelected 
                        ? 'Strict Mode: You can add new items but cannot remove existing ones'
                        : 'Strict Mode: You can remove items but cannot add new ones',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: AppSiteSelector(
              selectedApps: _currentApps,
              selectedSites: _currentSites,
              selectedCategories: _currentCategories,
              inLockdown: widget.inLockdown,
              blockSelected: widget.blockSelected,
              onSelectionChanged: (apps, sites, categoryTokens) {
                setState(() {
                  _currentApps = apps;
                  _currentSites = sites;
                  _currentCategories = categoryTokens;
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
  final bool inLockdown;
  final bool blockSelected;

  const AppSiteSelector({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    this.selectedCategories,
    required this.onSelectionChanged,
    required this.inLockdown,
    required this.blockSelected,
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
    print("handleMethodCall: ${call.method}");
    switch (call.method) {
      case 'onSelectionChanged':
       print("onSelectionChanged: ${call.arguments}");
        print("apps: ${call.arguments['apps']} = ${call.arguments['apps'].runtimeType}");
        print("sites: ${call.arguments['sites']} = ${call.arguments['sites'].runtimeType}");
        print("categories: ${call.arguments['categories']} = ${call.arguments['categories']?.runtimeType}");

        final selectedApps = List<String>.from(call.arguments['apps'] ?? []);
        final selectedSites = List<String>.from(call.arguments['sites'] ?? []);
        final selectedCategories = call.arguments['categories'] != null 
            ? List<String>.from(call.arguments['categories']) 
            : null;
        widget.onSelectionChanged(selectedApps, selectedSites, selectedCategories);
        break;
      default:
        print('Unhandled method ${call.method}');
    }
  }
}
