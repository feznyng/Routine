import 'package:Routine/services/browser_config.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:flutter/material.dart';

/// Step 2: Native Messaging Host Installation
class NativeMessagingHostStep extends StatefulWidget {
  final Browser browser;
  final Function(Browser, bool) onInstallationChanged;
  final Function(String?) onErrorChanged;
  final int totalBrowsers;
  final int currentBrowserIndex;

  const NativeMessagingHostStep({
    super.key,
    required this.browser,
    required this.onInstallationChanged,
    required this.onErrorChanged,
    required this.totalBrowsers,
    required this.currentBrowserIndex,
  });

  @override
  State<NativeMessagingHostStep> createState() => _NativeMessagingHostStepState();
}

class _NativeMessagingHostStepState extends State<NativeMessagingHostStep> {
  final BrowserService _browserService = BrowserService.instance;
  bool _nmhInstalled = false;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    // Initialize installation status - for now assume false, but could check actual status
    _nmhInstalled = false;
  }

  @override
  void didUpdateWidget(NativeMessagingHostStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.browser != widget.browser) {
      // Reset state for new browser
      setState(() {
        _nmhInstalled = false;
        _isInstalling = false;
      });
    }
  }

  Future<void> _installNativeMessagingHost() async {
    setState(() {
      _isInstalling = true;
    });
    
    // Clear any previous errors
    widget.onErrorChanged(null);
    
    try {
      final success = await _browserService.installNativeMessagingHost(widget.browser);
      
      setState(() {
        _nmhInstalled = success;
        _isInstalling = false;
      });
      
      if (success) {
        widget.onInstallationChanged(widget.browser, true);
      } else {
        widget.onErrorChanged('Failed to install native messaging host for ${widget.browser}');
      }
    } catch (e) {
      setState(() {
        _isInstalling = false;
      });
      widget.onErrorChanged('Error installing native messaging host: $e');
    }
  }

  bool canProceed() {
    return _nmhInstalled;
  }

  @override
  Widget build(BuildContext context) {
    final browserData = BrowserService.instance.getBrowserData(widget.browser);

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
          if (!_nmhInstalled && !_isInstalling)
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
    
    if (_nmhInstalled) {
      statusColor = colorScheme.primary;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Native Messaging Host Installed';
      statusDescription = 'Ready to communicate with ${browserData.appName}';
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.3);
    } else if (_isInstalling) {
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
            if (_isInstalling)
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
        onPressed: _installNativeMessagingHost,
        icon: const Icon(Icons.download_rounded),
        label: const Text('Install Native Messaging Host'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
