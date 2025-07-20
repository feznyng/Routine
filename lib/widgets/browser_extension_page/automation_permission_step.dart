import 'dart:async';
import 'dart:io';
import 'package:Routine/services/browser_config.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:Routine/setup.dart';
import 'package:flutter/material.dart';

/// Step for requesting automation permission on macOS for controllable browsers
class AutomationPermissionStep extends StatefulWidget {
  final Browser browser;
  final VoidCallback onPermissionGranted;

  const AutomationPermissionStep({
    Key? key,
    required this.browser,
    required this.onPermissionGranted,
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
    
    // If the browser changed, reset state and check permission for new browser
    if (oldWidget.browser != widget.browser) {
      _pollTimer?.cancel();
      setState(() {
        _hasPermission = false;
        _isChecking = false;
      });
      // Check permission for new browser (this will start polling if needed)
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
      widget.onPermissionGranted();
    } else {
      // Start polling if permission is not granted
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

    // Polling will already be started from _checkPermission if needed
    // But restart it to ensure it's active after the permission request
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
        widget.onPermissionGranted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final browserConfig = browserData[widget.browser]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grant Automation Permission for ${browserConfig.appName}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        if (_hasPermission) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Automation permission granted for ${browserConfig.appName}!',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            'To control ${browserConfig.appName} automatically, Routine needs automation permission.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('1. Click "Request Permission" below'),
                const Text('2. System Preferences will open to Automation settings'),
                const Text('3. Open the dropdown for Routine'),
                Text('4. Enable permissions for ${browserConfig.appName} by checking the box'),
                const Text('5. Return to this dialog'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isChecking) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Checking permission status...'),
            ),
          ] else if (_pollTimer?.isActive == true) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Waiting for permission to be granted...'),
            ),
          ] else ...[
            Center(
              child: FilledButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.security),
                label: const Text('Request Permission'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
