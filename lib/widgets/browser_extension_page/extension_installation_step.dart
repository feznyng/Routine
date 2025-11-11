import 'dart:async';
import 'package:Routine/services/browser_config.dart';
import 'package:flutter/material.dart';
import 'package:Routine/services/browser_service.dart';


class ExtensionInstallationStep extends StatefulWidget {
  final Browser browser;
  final Function(Browser) onInstallRequested;
  final Function(String?) onErrorChanged;
  final bool inGracePeriod;
  final int remainingSeconds;
  final int totalBrowsers;
  final int currentBrowserIndex;

  const ExtensionInstallationStep({
    Key? key,
    required this.browser,
    required this.onInstallRequested,
    required this.onErrorChanged,
    required this.inGracePeriod,
    required this.remainingSeconds,
    required this.totalBrowsers,
    required this.currentBrowserIndex,
  }) : super(key: key);

  @override
  State<ExtensionInstallationStep> createState() => _ExtensionInstallationStepState();
}

class _ExtensionInstallationStepState extends State<ExtensionInstallationStep> {
  late final ScrollController _scrollController;
  final BrowserService _browserService = BrowserService.instance;
  bool _isConnected = false;
  bool _isConnecting = false;
  StreamSubscription? _connectionStatusSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _updateConnectionStatus();
    _connectionStatusSubscription = _browserService.connectionStream.listen((_) {
      _updateConnectionStatus();
    });
  }

  @override
  void didUpdateWidget(ExtensionInstallationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.browser != widget.browser) {
      _updateConnectionStatus();
    }
  }

  void _updateConnectionStatus() {
    final wasConnected = _isConnected;
    final isNowConnected = _browserService.isBrowserConnected(widget.browser);
    
    setState(() {
      _isConnected = isNowConnected;
      if (!wasConnected && isNowConnected) {
        _isConnecting = false;
      }
    });
  }

  Future<void> _installBrowserExtension() async {
    setState(() {
      _isConnecting = true;
    });
    
    widget.onErrorChanged(null); // Clear any previous errors
    
    try {
      await _browserService.installBrowserExtension(widget.browser);
      widget.onInstallRequested(widget.browser);
    } catch (e) {
      widget.onErrorChanged('Error installing browser extension: $e');
      setState(() {
        _isConnecting = false;
      });
    }
  }

  bool canProceed() {
    return _isConnected;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _connectionStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browserData = BrowserService.instance.getBrowserData(widget.browser);

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, browserData),
          const SizedBox(height: 24),
          if (widget.inGracePeriod && widget.remainingSeconds > 0)
            _buildGracePeriodWarning(context),
          _buildStatusCard(context, browserData),
          const SizedBox(height: 24),
          if (!_isConnected && !_isConnecting)
            _buildActionButton(context, browserData),
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
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.extension_rounded,
            color: colorScheme.onTertiaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Install Browser Extension',
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
    Widget? statusWidget;
    
    if (_isConnected) {
      statusColor = colorScheme.primary;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Extension Connected';
      statusDescription = '${browserData.appName} extension is ready to use';
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.3);
    } else if (_isConnecting) {
      statusColor = colorScheme.secondary;
      statusIcon = Icons.hourglass_empty_rounded;
      statusText = 'Connecting...';
      statusDescription = 'Waiting for ${browserData.appName} extension to connect';
      backgroundColor = colorScheme.secondaryContainer.withOpacity(0.3);
      statusWidget = SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: statusColor,
        ),
      );
    } else {
      statusColor = colorScheme.outline;
      statusIcon = Icons.extension_rounded;
      statusText = 'Extension Required';
      statusDescription = '${browserData.appName} extension needs to be installed';
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
            statusWidget ?? Icon(
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
  
  Widget _buildGracePeriodWarning(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber[800]!,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Grace period active: ${widget.remainingSeconds}s remaining. '
              'Complete setup before time expires to avoid browser blocking.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.amber[800]!,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context, BrowserData browserData) {
    return Center(
      child: FilledButton.icon(
        onPressed: _installBrowserExtension,
        icon: const Icon(Icons.open_in_browser_rounded),
        label: Text('Open ${browserData.appName}'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
