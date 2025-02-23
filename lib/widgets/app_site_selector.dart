import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSiteSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Fixed height for the native view
      child: UiKitView(
        viewType: 'app_site_selector',
        creationParams: {
          'selectedApps': selectedApps,
          'selectedSites': selectedSites,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
