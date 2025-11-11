import 'package:Routine/services/browser_config.dart';
import 'package:flutter/material.dart';
import 'package:Routine/services/browser_service.dart';


class CompletionStep extends StatelessWidget {
  final List<Browser> connectedBrowsers;

  const CompletionStep({
    Key? key,
    required this.connectedBrowsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildBrowserList(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.celebration_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Setup Complete!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your browser configuration has been completed successfully.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrowserList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.web_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Configured Browsers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...connectedBrowsers.map((browser) => _buildBrowserItem(context, browser)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBrowserItem(BuildContext context, Browser browser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final browserData = BrowserService.instance.getBrowserData(browser);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          _getBrowserIcon(browser),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              browserData.appName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
  
  Widget _getBrowserIcon(Browser browser) {
    IconData iconData;
    Color iconColor;
    switch (browser) {
      case Browser.firefox:
        iconData = Icons.web_rounded;
        iconColor = Colors.orange;
        break;
      case Browser.chrome:
        iconData = Icons.web_rounded;
        iconColor = Colors.blue;
        break;
      case Browser.edge:
        iconData = Icons.web_rounded;
        iconColor = Colors.blue[700]!;
        break;
      case Browser.safari:
        iconData = Icons.web_rounded;
        iconColor = Colors.blue[600]!;
        break;
      case Browser.brave:
        iconData = Icons.web_rounded;
        iconColor = Colors.orange[700]!;
        break;
      case Browser.opera:
        iconData = Icons.web_rounded;
        iconColor = Colors.red;
        break;
    }
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 14,
      ),
    );
  }
}
