import 'dart:async';
import 'dart:io';
import 'package:Routine/services/browser_config.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:Routine/setup.dart';
import 'package:flutter/material.dart';


class AutomationPermissionStep extends StatefulWidget {
  final Browser browser;
  final Function(Browser, bool) onPermissionChanged;
  final Function(String?) onErrorChanged;
  final int totalBrowsers;
  final int currentBrowserIndex;

  const AutomationPermissionStep({
    Key? key,
    required this.browser,
    required this.onPermissionChanged,
    required this.onErrorChanged,
    this.totalBrowsers = 1,
    this.currentBrowserIndex = 0,
  }) : super(key: key);

  @override
  State<AutomationPermissionStep> createState() => _AutomationPermissionStepState();
}

class _AutomationPermissionStepState extends State<AutomationPermissionStep> {
  final BrowserService _browserService = BrowserService.instance;
  bool _isChecking = false;
  bool _hasPermission = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void didUpdateWidget(AutomationPermissionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.browser != widget.browser) {
      _pollTimer?.cancel();
      setState(() {
        _hasPermission = false;
        _isChecking = false;
      });
      _checkPermission();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    if (!Platform.isMacOS) return;
    
    setState(() {
      _isChecking = true;
    });

    final hasPermission = await _browserService.hasAutomationPermission(widget.browser);
    
    setState(() {
      _hasPermission = hasPermission;
      _isChecking = false;
    });

    if (hasPermission) {
      widget.onPermissionChanged(widget.browser, true);
    } else {
      logger.i('Permission not granted for ${widget.browser}, starting polling');
      _startPolling();
    }
  }

  Future<void> _requestPermission() async {
    if (!Platform.isMacOS) return;

    await _browserService.requestAutomationPermission(
      widget.browser,
      openPrefsOnReject: true,
    );
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    logger.i('Starting polling for ${widget.browser} automation permission');
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      logger.d('Polling ${widget.browser} automation permission...');
      final hasPermission = await _browserService.hasAutomationPermission(widget.browser);
      
      if (hasPermission) {
        logger.i('${widget.browser} automation permission granted!');
        setState(() {
          _hasPermission = true;
        });
        timer.cancel();
        widget.onPermissionChanged(widget.browser, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final browserConfig = browserData[widget.browser]!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, browserConfig),
          const SizedBox(height: 24),
          _buildStatusCard(context, browserConfig),
          const SizedBox(height: 24),
          if (!_hasPermission) ...[
            _buildActionButton(context),
            const SizedBox(height: 24),
            _buildInstructionsCard(context, browserConfig),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, BrowserData browserConfig) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.security_rounded,
            color: colorScheme.onSecondaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Automation Permission',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Required for ${browserConfig.appName}',
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
  
  Widget _buildStatusCard(BuildContext context, BrowserData browserConfig) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color backgroundColor;
    
    if (_hasPermission) {
      statusColor = colorScheme.primary;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Permission Granted';
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.3);
    } else if (_isChecking || _pollTimer?.isActive == true) {
      statusColor = colorScheme.secondary;
      statusIcon = Icons.hourglass_empty_rounded;
      statusText = _isChecking ? 'Checking Permission...' : 'Waiting for Permission...';
      backgroundColor = colorScheme.secondaryContainer.withOpacity(0.3);
    } else {
      statusColor = colorScheme.outline;
      statusIcon = Icons.security_rounded;
      statusText = 'Permission Required';
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
            if (_isChecking || _pollTimer?.isActive == true)
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
                    _hasPermission
                        ? 'Routine can now control ${browserConfig.appName}'
                        : 'Routine needs permission to control ${browserConfig.appName}',
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

  
  Widget _buildInstructionsCard(BuildContext context, BrowserData browserConfig) {
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
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'How to Grant Permission',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildInstructionSteps(context, browserConfig),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildInstructionSteps(BuildContext context, BrowserData browserConfig) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final steps = [
      'Click "Request Permission" above',
      'Accept the prompt if it appears',
      'Otherwise, System Preferences will open to Automation settings',
      'Find and expand the "Routine" section',
      'Check the box next to "${browserConfig.appName}"',
      'Return to this dialog - permission will be detected automatically',
    ];
    
    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  Widget _buildActionButton(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: _requestPermission,
        icon: const Icon(Icons.security_rounded),
        label: const Text('Request Permission'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
