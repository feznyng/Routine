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
  late MethodChannel _channel;

  @override
  Widget build(BuildContext context) {
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
    _channel = MethodChannel('app_site_selector');
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    print("handleMethodCall: ${call.method}");
    switch (call.method) {
      case 'onSelectionChanged':
        final List<String> selectedApps = List<String>.from(call.arguments['apps'] ?? []);
        final List<String> selectedSites = List<String>.from(call.arguments['sites'] ?? []);

        widget.onSave(selectedApps, selectedSites);
        break;
      default:
        print('Unhandled method ${call.method}');
    }
  }
}
