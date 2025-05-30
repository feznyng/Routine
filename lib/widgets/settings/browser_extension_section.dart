import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:async';
import '../../services/browser_extension_service.dart';
import '../../services/strict_mode_service.dart';
import '../../pages/browser_extension_onboarding_page.dart';
import '../../services/browser_config.dart';

class BrowserExtensionSection extends StatefulWidget {
  final Future<void> Function() onRestartOnboarding;

  const BrowserExtensionSection({
    Key? key,
    required this.onRestartOnboarding,
  }) : super(key: key);

  @override
  State<BrowserExtensionSection> createState() => _BrowserExtensionSectionState();
}

class _BrowserExtensionSectionState extends State<BrowserExtensionSection> {
  final BrowserExtensionService _browserExtensionService = BrowserExtensionService();
  final StrictModeService _strictModeService = StrictModeService();
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _gracePeriodTimer;
  Timer? _cooldownTimer;

  List<Browser> _installedBrowsers = [];

  @override
  void initState() {
    super.initState();
    
    // Subscribe to connection status changes
    _connectionSubscription = _browserExtensionService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Start a timer to update the cooldown time display
    _startCooldownTimer();

    // Load installed browsers
    _loadInstalledBrowsers();
  }

  Future<void> _loadInstalledBrowsers() async {
    final browsers = await _browserExtensionService.getInstalledSupportedBrowsers();
    if (mounted) {
      setState(() {
        _installedBrowsers = browsers.map((b) => b.browser).toList();
      });
    }
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _connectionSubscription?.cancel();
    _gracePeriodTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }
  
  void _startCooldownTimer() {
    // Cancel any existing timer
    _cooldownTimer?.cancel();
    
    // Create a new timer that fires every second
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild with the updated cooldown time
        });
      }
    });
  }

  Future<void> _showOnboardingDialog() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {      
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => BrowserExtensionOnboardingPage(
            inGracePeriod: _strictModeService.isInExtensionGracePeriod,
          ),
        ),
      );
      
      // Update state after dialog is closed
      setState(() {});

    }
  }
  
  String _getBrowserName(Browser browser) {
    return browser.name.substring(0, 1).toUpperCase() + browser.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final connectedBrowsers = _browserExtensionService.connectedBrowsers;
    final isInGracePeriod = _strictModeService.isInExtensionGracePeriod;
    final isInCooldown = _strictModeService.isInExtensionCooldown;
    final remainingGraceSeconds = _strictModeService.remainingGracePeriodSeconds;
    final remainingCooldownMinutes = _strictModeService.remainingCooldownMinutes;
    final isBlockingBrowsers = _strictModeService.effectiveBlockBrowsersWithoutExtension;
  
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Browsers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connected browsers
                if (connectedBrowsers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...connectedBrowsers.map((browser) {
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(_getBrowserName(browser)),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],

                // Unconnected but installed browsers
                if (_installedBrowsers.isNotEmpty) ...[                  
                  ...(_installedBrowsers
                    .where((b) => !connectedBrowsers.contains(b))
                    .map((browser) {
                      return ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        title: Text(_getBrowserName(browser)),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      );
                    })
                  ).toList(),
                  const SizedBox(height: 8),
                ],

                // No browsers connected message
                if (connectedBrowsers.isEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.orange),
                    title: const Text('No browsers connected'),
                    subtitle: const Text('Set up the browser extension to block distracting websites'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Warning about browser blocking when no browsers are connected
                if (isBlockingBrowsers && connectedBrowsers.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Browser Blocking Enabled',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isInGracePeriod
                                    ? 'You have ${remainingGraceSeconds} seconds to connect the extension before browsers are blocked. If you exit this setup, a 10-minute cooldown will be enforced.'
                                    : isInCooldown
                                        ? 'Browsers are currently blocked. You must wait ${remainingCooldownMinutes} minutes before trying to set up the extension again.'
                                        : 'Browsers will be blocked until you connect the extension. Once you start setup, you\'ll have 60 seconds to complete it before a 10-minute cooldown is enforced.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Setup button
                ElevatedButton(
                  onPressed: isInCooldown ? null : () async {
                    await widget.onRestartOnboarding();
                    await _showOnboardingDialog();
                  },
                  child: Text(isInCooldown
                      ? 'Wait ${remainingCooldownMinutes}m to try again'
                      : 'Set Up Browsers'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
