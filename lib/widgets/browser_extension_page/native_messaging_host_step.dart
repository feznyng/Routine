import 'package:Routine/services/browser_config.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:flutter/material.dart';

/// Step 2: Native Messaging Host Installation
class NativeMessagingHostStep extends StatelessWidget {
  final Browser browser;
  final bool nmhInstalled;
  final bool isInstalling;
  final VoidCallback onInstall;
  final int totalBrowsers;
  final int currentBrowserIndex;

  const NativeMessagingHostStep({
    Key? key,
    required this.browser,
    required this.nmhInstalled,
    required this.isInstalling,
    required this.onInstall,
    required this.totalBrowsers,
    required this.currentBrowserIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final browserData = BrowserService.instance.getBrowserData(browser);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, browserData),
          const SizedBox(height: 24),

          // Status card
          _buildStatusCard(context, browserData),
          const SizedBox(height: 24),
          
          // Action button
          if (!nmhInstalled && !isInstalling)
            _buildActionButton(context),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, BrowserData browserData) {
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
            Icons.download_rounded,
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
                'Install Native Messaging Host',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Required for ${browserData.appName}',
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
  
  Widget _buildStatusCard(BuildContext context, BrowserData browserData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;
    Color backgroundColor;
    
    if (nmhInstalled) {
      statusColor = colorScheme.primary;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Native Messaging Host Installed';
      statusDescription = 'Ready to communicate with ${browserData.appName}';
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.3);
    } else if (isInstalling) {
      statusColor = colorScheme.secondary;
      statusIcon = Icons.hourglass_empty_rounded;
      statusText = 'Installing...';
      statusDescription = 'Installing Native Messaging Host for ${browserData.appName}';
      backgroundColor = colorScheme.secondaryContainer.withOpacity(0.3);
    } else {
      statusColor = colorScheme.outline;
      statusIcon = Icons.download_rounded;
      statusText = 'Installation Required';
      statusDescription = 'Native Messaging Host needs to be installed';
      backgroundColor = colorScheme.surfaceVariant.withOpacity(0.3);
    }
    
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (isInstalling)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: statusColor,
                ),
              )
            else
              Icon(
                statusIcon,
                color: statusColor,
                size: 32,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onInstall,
        icon: const Icon(Icons.download_rounded),
        label: const Text('Install Native Messaging Host'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
