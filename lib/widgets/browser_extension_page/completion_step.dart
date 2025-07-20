import 'package:Routine/services/browser_config.dart';
import 'package:flutter/material.dart';
import 'package:Routine/services/browser_service.dart';

/// Step 4: Completion
class CompletionStep extends StatelessWidget {
  final List<Browser> connectedBrowsers;

  const CompletionStep({
    Key? key,
    required this.connectedBrowsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Complete',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Browser configuration has been completed successfully.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configured browsers:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...connectedBrowsers.map((browser) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text((BrowserService.instance.getBrowserData(browser)).appName),
                ],
              ),
            )),
          ],
        ),
      ],
    );
  }
}
