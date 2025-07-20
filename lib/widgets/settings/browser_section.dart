import 'package:Routine/setup.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:async';
import '../../services/browser_service.dart';
import '../../services/strict_mode_service.dart';
import '../../pages/browser_extension_onboarding_page.dart';
import '../../services/browser_config.dart';

class BrowserSection extends StatefulWidget {
  final Future<void> Function() onRestartOnboarding;

  const BrowserSection({
    super.key,
    required this.onRestartOnboarding,
  });

  @override
  State<BrowserSection> createState() => _BrowserSectionState();
}

class _BrowserSectionState extends State<BrowserSection> {
  final BrowserService _browserExtensionService = BrowserService();
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
    
    // Start a timer to update the cooldown time display and check initial connection period
    _startCooldownTimer();
    
    // Force refresh when initial connection period ends
    if (_browserExtensionService.isInitialConnectionPeriod) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() {});
      });
    }

    // Load installed browsers
    _loadInstalledBrowsers();
  }

  Future<void> _loadInstalledBrowsers() async {
    final browsers = await _browserExtensionService.getInstalledSupportedBrowsers(connected: null);

    logger.i("installed browsers: $browsers");

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
            inGracePeriod: _browserExtensionService.isInGracePeriod,
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
    // Show loading during initial connection period
    if (_browserExtensionService.isInitialConnectionPeriod) {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Text(
                    'Browsers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking browser connections...'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final connectedBrowsers = _installedBrowsers.where((b) => _browserExtensionService.isBrowserConnected(b));
    final disconnectedBrowsers = _installedBrowsers.where((b) => !connectedBrowsers.contains(b));
    final isInCooldown = _browserExtensionService.isInCooldown;
    final remainingCooldownMinutes = _browserExtensionService.remainingCooldownMinutes;
    final isBlockingBrowsers = _strictModeService.effectiveBlockBrowsersWithoutExtension && disconnectedBrowsers.isNotEmpty;
  
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browsers',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: isInCooldown ? null : () async {
                    await widget.onRestartOnboarding();
                    await _showOnboardingDialog();
                  },
                  child: Text(isInCooldown
                      ? 'Wait ${remainingCooldownMinutes}m to try again'
                      : 'Set Up'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBlockingBrowsers)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                                isInCooldown
                                  ? 'Disconnected browsers are currently blocked. You must wait $remainingCooldownMinutes minutes before trying to set up the extension again.'
                                  : 'Disconnected browsers will be blocked until you connect them.',
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Browser Lists
                if (connectedBrowsers.isNotEmpty || disconnectedBrowsers.isNotEmpty) ...[
                  // Connected browsers
                  if (connectedBrowsers.isNotEmpty)
                    ...connectedBrowsers.map((browser) => ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(_getBrowserName(browser)),
                      subtitle: const Text('Connected'),
                      dense: true,
                    )),

                  // Unconnected but installed browsers
                  if (disconnectedBrowsers.isNotEmpty)
                    ...disconnectedBrowsers.map((browser) => ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text(_getBrowserName(browser)),
                      subtitle: const Text('Not Connected'),
                      dense: true,
                    )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
