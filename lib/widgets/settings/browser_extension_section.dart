import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../services/browser_extension_service.dart';
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
  bool _isSetupCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
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
      await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BrowserExtensionOnboardingDialog(
          selectedSites: const [], // No pre-selected sites
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
    final isExtensionSetup = _isSetupCompleted && BrowserExtensionService.instance.isExtensionConnected;

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
            Row(
              children: [
                Icon(
                  isExtensionSetup ? Icons.check_circle : Icons.error,
                  color: isExtensionSetup ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isExtensionSetup
                      ? 'Browser extension is set up'
                      : 'Browser extension setup required',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isExtensionSetup ? Colors.green : Colors.orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // First reset the setup status
                await widget.onRestartOnboarding();
                // Then show the onboarding dialog
                await _showOnboardingDialog();
              },
              child: Text(_isSetupCompleted
                  ? 'Configure Browser Extension'
                  : 'Set Up Browser Extension'),
            ),
          ],
        ),
      ),
    );
  }
}
