import 'package:Routine/services/browser_config.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:Routine/services/strict_mode_service.dart';
import 'package:flutter/material.dart';

/// Step 1: Browser Selection
class BrowserSelectionStep extends StatelessWidget {
  final List<Browser> installedBrowsers;
  final List<Browser> selectedBrowsers;
  final Function(Browser) onToggleBrowser;
  late final StrictModeService _strictModeService;

  BrowserSelectionStep({
    Key? key,
    required this.installedBrowsers,
    required this.selectedBrowsers,
    required this.onToggleBrowser,
  }) : super(key: key) {
    _strictModeService = StrictModeService.instance;
  }

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

    final connectedBrowsers = installedBrowsers
        .where((b) => BrowserService.instance.isBrowserConnected(b))
        .toList();
    final unconnectedBrowsers = installedBrowsers
        .where((b) => !BrowserService.instance.isBrowserConnected(b))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select browsers to configure',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Select browsers to configure. Some browsers require browser extensions, while others (like Safari and Chrome on macOS) use automation permissions.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (_strictModeService.effectiveBlockBrowsersWithoutExtension && unconnectedBrowsers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Important',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Any browsers you don\'t set up now will be blocked for at least 10 minutes. '
                  'Make sure to select all browsers you want to use.',
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            children: [
              if (connectedBrowsers.isNotEmpty) ...[
                ...connectedBrowsers.map((browser) => ListTile(
                      title: Text(BrowserService.instance.getBrowserData(browser).appName),
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                    )),
                const Divider(height: 24),
              ],
              if (unconnectedBrowsers.isNotEmpty) ...[
                ...unconnectedBrowsers.map((browser) {
                  final isSelected = selectedBrowsers.contains(browser);
                  return CheckboxListTile(
                    title: Text(BrowserService.instance.getBrowserData(browser).appName),
                    value: isSelected,
                    onChanged: (_) => onToggleBrowser(browser),
                    secondary: _getBrowserIcon(browser),
                  );
                }),
              ],
            ],
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
