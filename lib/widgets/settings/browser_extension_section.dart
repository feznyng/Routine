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
  bool _isSetupCompleted = false;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _gracePeriodTimer;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
    
    // Subscribe to connection status changes
    _connectionSubscription = _browserExtensionService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          // No need to update any state variable as we'll use BrowserExtensionService.instance.isExtensionConnected
          // directly in the build method
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _connectionSubscription?.cancel();
    _gracePeriodTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkSetupStatus() async {
    final isCompleted = await _browserExtensionService.isSetupCompleted();
    if (mounted) {
      setState(() {
        _isSetupCompleted = isCompleted;
      });
    }
  }

  Future<void> _showOnboardingDialog() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final isInGracePeriod = _strictModeService.isInExtensionGracePeriod;
      
      await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BrowserExtensionOnboardingDialog(
          selectedSites: const [], // No pre-selected sites
          inGracePeriod: isInGracePeriod, // Pass the grace period flag
          onComplete: (sites) {
            // Mark setup as completed
            _browserExtensionService.markSetupCompleted();
            Navigator.of(context).pop(sites);
            
            // Refresh the state
            if (mounted) {
              setState(() {
                _isSetupCompleted = true;
              });
            }
          },
          onSkip: () {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension),
                const SizedBox(width: 8),
                Text(
                  'Browser Extension',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
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
                  // Start the grace period
                  _strictModeService.startExtensionGracePeriod();
                  
                  // Set up a timer to update the UI during grace period
                  _gracePeriodTimer?.cancel();
                  _gracePeriodTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    if (mounted) {
                      setState(() {});
                    }
                    
                    // Check if extension is connected or grace period ended
                    if (BrowserExtensionService.instance.isExtensionConnected) {
                      _strictModeService.endExtensionGracePeriod();
                      timer.cancel();
                    } else if (!_strictModeService.isInExtensionGracePeriod) {
                      timer.cancel();
                    }
                  });
                  
                  // First reset the setup status
                  await widget.onRestartOnboarding();
                  // Then show the onboarding dialog
                  await _showOnboardingDialog();
                },
                child: Text(isInCooldown
                    ? 'Wait ${_strictModeService.remainingCooldownMinutes}m to try again'
                    : 'Set Up Browser Extension'),
              ),
          ],
        ),
      ),
    );
  }
}
