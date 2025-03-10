import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:async';
import '../../services/browser_extension_service.dart';
import '../../services/strict_mode_service.dart';
import '../browser_extension_onboarding_dialog.dart';

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
      await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BrowserExtensionOnboardingDialog(
          selectedSites: const [], // No pre-selected sites
          onComplete: (sites) {
            setState(() {});
            Navigator.of(context).pop(sites);
          },
          onSkip: () {
            setState(() {});
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isExtensionConnected = BrowserExtensionService.instance.isExtensionConnected;
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
              'Browser Extension',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 16),
            Text(
              'The browser extension allows Routine to block distracting websites during focus sessions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Extension connection status
            Row(
              children: [
                Icon(
                  isExtensionConnected ? Icons.check_circle : (isInGracePeriod ? Icons.timer : Icons.error),
                  color: isExtensionConnected ? Colors.green : (isInGracePeriod ? Colors.blue : (isInCooldown ? Colors.red : Colors.orange)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExtensionConnected
                        ? 'Browser extension is connected'
                        : 'Browser extension is disconnected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isExtensionConnected ? Colors.green : (isInGracePeriod ? Colors.blue : (isInCooldown ? Colors.red : Colors.orange)),
                        ),
                  ),
                ),
              ],
            ),
            
            // Warning about browser blocking when extension is not connected
            if (isBlockingBrowsers && !isExtensionConnected)
              Container(
                margin: const EdgeInsets.only(top: 16.0),
                padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 16),
            // Only show the button if the extension is not connected
            if (!isExtensionConnected)
              ElevatedButton(
                onPressed: isInCooldown ? null : () async {
                  await widget.onRestartOnboarding();
                  // Then show the onboarding dialog
                  await _showOnboardingDialog();
                },
                child: Text(isInCooldown
                    ? 'Wait ${remainingCooldownMinutes}m to try again'
                    : 'Set Up Browser Extension'),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
