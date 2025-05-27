import 'package:flutter/material.dart';
import 'package:Routine/services/browser_extension_service.dart';

/// Step 1: Browser Selection
class BrowserSelectionStep extends StatelessWidget {
  final List<Browser> installedBrowsers;
  final List<Browser> selectedBrowsers;
  final Function(Browser) onToggleBrowser;

  const BrowserSelectionStep({
    Key? key,
    required this.installedBrowsers,
    required this.selectedBrowsers,
    required this.onToggleBrowser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (installedBrowsers.isEmpty) {
      return const Center(
        child: Text(
          'No supported browsers found on your system.\n'
          'Please install at least one of the following browsers:\n'
          'Chrome, Firefox, Edge, Brave, or Opera',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select browsers to configure',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'The Routine browser extension needs to be installed on each browser you use.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: installedBrowsers.length,
            itemBuilder: (context, index) {
              final browser = installedBrowsers[index];
              final isSelected = selectedBrowsers.contains(browser);
              
              return CheckboxListTile(
                title: Text(browser.name),
                value: isSelected,
                onChanged: (_) => onToggleBrowser(browser),
                secondary: _getBrowserIcon(browser),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _getBrowserIcon(Browser browser) {
    IconData iconData;
    Color iconColor;
    
    // Since Firefox is currently the only browser in the enum,
    // we can set these values directly
    iconData = Icons.web;
    iconColor = Colors.orange;
    
    return Icon(iconData, color: iconColor);
  }
}
