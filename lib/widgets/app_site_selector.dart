import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSiteSelectorPage extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final Function(List<String>, List<String>) onSave;

  const AppSiteSelectorPage({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
  });

  @override
  State<AppSiteSelectorPage> createState() => _AppSiteSelectorPageState();
}

class _AppSiteSelectorPageState extends State<AppSiteSelectorPage> {
  List<String> _currentApps = [];
  List<String> _currentSites = [];

  @override
  void initState() {
    super.initState();
    _currentApps = List.from(widget.selectedApps);
    _currentSites = List.from(widget.selectedSites);
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
              widget.onSave(_currentApps, _currentSites);
            },
            child: const Text('Done'),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: AppSiteSelector(
              selectedApps: _currentApps,
              selectedSites: _currentSites,
              onSelectionChanged: (apps, sites) {
                setState(() {
                  _currentApps = apps;
                  _currentSites = sites;
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
  final Function(List<String>, List<String>) onSelectionChanged;

  const AppSiteSelector({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
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

        final selectedApps = List<String>.from(call.arguments['apps'] ?? []);
        final selectedSites = List<String>.from(call.arguments['sites'] ?? []);
        widget.onSelectionChanged(selectedApps, selectedSites);
        break;
      default:
        print('Unhandled method ${call.method}');
    }
  }
}
