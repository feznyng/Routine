import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSiteSelectorPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: AppSiteSelector(
              selectedApps: selectedApps,
              selectedSites: selectedSites,
              onSave: onSave,
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
  final Function(List<String>, List<String>) onSave;

  AppSiteSelector({
    Key? key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
  }) : super(key: key ?? GlobalKey());

  @override
  State<AppSiteSelector> createState() => _AppSiteSelectorState();
}

class _AppSiteSelectorState extends State<AppSiteSelector> {
  MethodChannel? _channel;
  int? _viewId;

  @override
  void dispose() {
    if (_viewId != null) {
      _channel?.invokeMethod('dispose');
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

        final List<String> selectedApps = List<String>.from(call.arguments['apps'] ?? []);
        final List<String> selectedSites = List<String>.from(call.arguments['sites'] ?? []);
        print("calling onSave with $selectedApps, $selectedSites");
        widget.onSave(selectedApps, selectedSites);
        break;
      default:
        print('Unhandled method ${call.method}');
    }
  }
}
