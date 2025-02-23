import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSiteSelector extends StatefulWidget {
  final List<String> selectedApps;
  final List<String> selectedSites;
  final Function(List<String>, List<String>) onSave;

  const AppSiteSelector({
    super.key,
    required this.selectedApps,
    required this.selectedSites,
    required this.onSave,
  });

  @override
  State<AppSiteSelector> createState() => _AppSiteSelectorState();
}

class _AppSiteSelectorState extends State<AppSiteSelector> {
  MethodChannel? _channel;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 550, // Fixed height for the native view
      child: UiKitView(
        viewType: 'app_site_selector',
        creationParams: {
          'selectedApps': widget.selectedApps,
          'selectedSites': widget.selectedSites,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }

  void _onPlatformViewCreated(int id) {
    if (_isDisposed) return;
    
    _channel = MethodChannel('app_site_selector_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (_isDisposed) return;
    
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
