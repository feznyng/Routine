import 'package:Routine/services/browser_config.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:flutter/material.dart';

/// Step 2: Native Messaging Host Installation
class NativeMessagingHostStep extends StatelessWidget {
  final Browser browser;
  final bool nmhInstalled;
  final VoidCallback onInstall;
  final int totalBrowsers;
  final int currentBrowserIndex;

  const NativeMessagingHostStep({
    Key? key,
    required this.browser,
    required this.nmhInstalled,
    required this.onInstall,
    required this.totalBrowsers,
    required this.currentBrowserIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = BrowserService.instance.getBrowserData(browser).appName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Install Native Messaging Host for $name',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Browser ${currentBrowserIndex + 1} of $totalBrowsers',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'The Native Messaging Host is required for the $name extension to communicate with Routine.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Icon(
                nmhInstalled ? Icons.check_circle : Icons.info,
                color: nmhInstalled ? Colors.green : Colors.blue,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                nmhInstalled
                    ? 'Native Messaging Host is installed'
                    : 'Native Messaging Host needs to be installed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (!nmhInstalled)
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Install Native Messaging Host'),
                  onPressed: onInstall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
