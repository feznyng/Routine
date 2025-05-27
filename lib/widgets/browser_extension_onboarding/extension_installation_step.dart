import 'package:flutter/material.dart';
import 'package:Routine/services/browser_extension_service.dart';

/// Step 3: Extension Installation
class ExtensionInstallationStep extends StatelessWidget {
  final Browser browser;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onInstall;
  final bool inGracePeriod;
  final int remainingSeconds;
  final int totalBrowsers;
  final int currentBrowserIndex;

  const ExtensionInstallationStep({
    Key? key,
    required this.browser,
    required this.isConnected,
    required this.isConnecting,
    required this.onInstall,
    required this.inGracePeriod,
    required this.remainingSeconds,
    required this.totalBrowsers,
    required this.currentBrowserIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = BrowserExtensionService.instance.getBrowserData(browser).appName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Install Extension for $name',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Browser ${currentBrowserIndex + 1} of $totalBrowsers',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'The browser extension needs to be installed to block distracting websites and applications.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        
        // Grace period warning if applicable
        if (inGracePeriod)
          Container(
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
                    const Icon(Icons.warning, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Grace Period Active',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Time remaining: $remainingSeconds seconds',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'You must complete the extension setup before the grace period expires, '
                  'or browsers will be blocked for 10 minutes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              if (isConnected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                )
              else if (isConnecting)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Waiting for extension to connect...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              else
                const Icon(
                  Icons.extension,
                  color: Colors.blue,
                  size: 64,
                ),
              const SizedBox(height: 16),
              Text(
                isConnected
                    ? '$name extension is connected'
                    : '$name extension needs to be installed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (!isConnected)
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  label: Text('Open $name to Install Extension'),
                  onPressed: onInstall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
