import 'dart:async';
import 'package:Routine/util.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/desktop_service.dart';
import '../services/browser_extension_service.dart';
import '../services/strict_mode_service.dart';

class BrowserExtensionOnboardingDialog extends StatefulWidget {
  final List<String> selectedSites;
  final Function(List<String>) onComplete;
  final VoidCallback onSkip;

  const BrowserExtensionOnboardingDialog({
    super.key,
    required this.selectedSites,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<BrowserExtensionOnboardingDialog> createState() => _BrowserExtensionOnboardingDialogState();
}

class _BrowserExtensionOnboardingDialogState extends State<BrowserExtensionOnboardingDialog> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  List<String> _detectedBrowsers = [];
  bool _isLoading = true;
  bool _manifestInstalled = false;
  bool _isInstallingManifest = false;
  String? _manifestInstallError;
  bool _isInstallingExtension = false;
  String? _extensionInstallError;
  
  // Grace period tracking
  bool _startedGracePeriod = false;
  int _remainingGracePeriodSeconds = 0;
  Timer? _gracePeriodCountdownTimer;
  StreamSubscription? _gracePeriodExpirationSubscription;
  
  // Subscription for extension connection status
  StreamSubscription<bool>? _connectionSubscription;
  
  // Timer for periodically trying to connect to NMH
  Timer? _connectionAttemptTimer;
  
  @override
  void initState() {
    super.initState();
    _detectInstalledBrowsers();
    _startedGracePeriod = false;
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _connectionSubscription?.cancel();
    _connectionAttemptTimer?.cancel();
    _gracePeriodCountdownTimer?.cancel();
    _gracePeriodExpirationSubscription?.cancel();
    
    super.dispose();
  }
  
  // Start a timer to update the grace period countdown
  void _startGracePeriodCountdown() {
    if (!StrictModeService.instance.effectiveBlockBrowsersWithoutExtension) {
      return;
    }

    setState(() {
      _startedGracePeriod = true;
    });

    _gracePeriodExpirationSubscription = StrictModeService.instance.gracePeriodExpirationStream
        .listen((_) => _onGracePeriodExpired());
    StrictModeService.instance.startExtensionGracePeriod();

    _gracePeriodCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingGracePeriodSeconds = StrictModeService.instance.remainingGracePeriodSeconds;
          
          // If grace period has expired, cancel the timer
          if (_remainingGracePeriodSeconds <= 0) {
            timer.cancel();
            _gracePeriodCountdownTimer = null;
          }
        });
      }
    });
  }
  
  // Handle grace period expiration
  void _onGracePeriodExpired() {
    if (mounted) {
      // Close the dialog when grace period expires
      widget.onSkip();
    }
  }
  
  Future<void> _detectInstalledBrowsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get installed applications
      final installedApps = await DesktopService.getInstalledApps();
      
      // Filter for supported browsers (only Firefox for now)
      final browsers = installedApps
          .where((app) => app.name.toLowerCase().contains('firefox'))
          .map((app) => app.name)
          .toList();
      
      setState(() {
        _detectedBrowsers = browsers;
        _isLoading = false;
      });
    } catch (e, st) {
      Util.report('error detecting browsers', e, st);
      setState(() {
        _detectedBrowsers = [];
        _isLoading = false;
      });
    }
  }
  
  Future<void> _installNativeMessagingHost() async {
    setState(() {
      _isInstallingManifest = true;
      _manifestInstallError = null;
    });
    
    try {
      final browserExtensionService = BrowserExtensionService.instance;
      
      // Always install the native messaging host and manifest during onboarding
      // to ensure they're properly configured
      final success = await browserExtensionService.installNativeMessagingHost();
      
      setState(() {
        _manifestInstalled = success;
        _isInstallingManifest = false;
        
        if (!success) {
          _manifestInstallError = 'Failed to install native messaging host. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isInstallingManifest = false;
        _manifestInstalled = false;
        _manifestInstallError = 'Error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _installBrowserExtension(String browserName) async {
    setState(() {
      _isInstallingExtension = true;
      _extensionInstallError = null;
    });
    
    try {
      final browserExtensionService = BrowserExtensionService.instance;
      final success = await browserExtensionService.installBrowserExtension(browserName);
      
      setState(() {
        // Don't set _extensionInstalled to true here
        // It will be set by the connection listener when the extension actually connects
        _isInstallingExtension = false;
        
        if (!success) {
          _extensionInstallError = 'Failed to install browser extension. Please try again or install it manually.';
        } else {
          // Start periodic connection attempts
          _startPeriodicConnectionAttempts();
        }
      });
    } catch (e) {
      setState(() {
        _isInstallingExtension = false;
        _extensionInstallError = 'Error: ${e.toString()}';
      });
    }
  }
  
  // Start periodic attempts to connect to the Native Messaging Host
  void _startPeriodicConnectionAttempts() {
    // Cancel any existing timer
    _connectionAttemptTimer?.cancel();
    
    // Try to connect immediately
    _attemptConnection();
    
    // Set up a timer to try connecting every 2 seconds
    _connectionAttemptTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Check if the extension is already connected
      if (BrowserExtensionService.instance.isExtensionConnected) {
        setState(() {
          _isInstallingExtension = false;
        });
        // If connected, cancel the timer
        timer.cancel();
        _connectionAttemptTimer = null;
        return;
      }
      
      // Try to connect
      _attemptConnection();
    });
  }
  
  // Attempt to connect to the Native Messaging Host
  Future<void> _attemptConnection() async {
    if (!BrowserExtensionService.instance.isExtensionConnected) {
      await BrowserExtensionService.instance.connectToNMH();
    }
  }
  
  void _nextStep() {
    if (_currentStep < _getStepTitles().length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // If moving to the extension installation step, start periodic connection attempts
      if (_currentStep == 2) { // Extension installation step
        _startGracePeriodCountdown();
        _startPeriodicConnectionAttempts();
      }
    } else {
      // Complete the onboarding
      widget.onComplete(widget.selectedSites);
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  List<String> _getStepTitles() {
    return [
      'Detect Browsers',
      'Install Native Messaging Host',
      'Install Browser Extension',
    ];
  }
  
  Widget _buildBrowserDetectionStep() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_detectedBrowsers.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'No supported browsers detected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We currently support Firefox. Please install it to use website blocking.',
            textAlign: TextAlign.center,
          ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text(
          'Supported browsers detected:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(_detectedBrowsers.length, (index) {
          final words = _detectedBrowsers[index].split(' ');
          final titleCase = words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
          return ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(titleCase),
          );
        }),
        const SizedBox(height: 16),
        Text(
          Platform.isWindows
              ? 'Please open any additional browsers you want to block sites on. Routine can only detect running browsers on Windows.'
              : 'To block websites, please set up our extension for each browser you have installed.',
          style: const TextStyle(fontSize: 14),
        ),
        ],
      ),
    );
  }
  
  Widget _buildInstallNativeMessagingHostStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        const SizedBox(height: 16),
        const Text(
          'The native messaging host allows the browser extension to communicate with Routine.',
          textAlign: TextAlign.center,
        ),
        if (Platform.isMacOS)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'You will be prompted to select the Mozilla NativeMessagingHosts directory.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        if (Platform.isWindows)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'The native messaging host will be registered in the Windows registry.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: 16),
        if (_manifestInstallError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _manifestInstallError!,
                style: TextStyle(color: Colors.red.shade800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (!_manifestInstalled)
          _isInstallingManifest
              ? const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Installing native messaging host...'),
                  ],
                )
              : ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Install Native Messaging Host'),
                  onPressed: _installNativeMessagingHost,
                )
        else
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Native Messaging Host installed successfully!'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstallExtensionStep() {
    // Get the actual connection status from the service
    final isExtensionConnected = BrowserExtensionService.instance.isExtensionConnected;
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        const SizedBox(height: 16),
        const Text(
          'The browser extension is required to block websites in your browser.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'This will open your browser to install the extension. Follow the instructions in the browser to complete installation.',
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (!isExtensionConnected && _startedGracePeriod && _remainingGracePeriodSeconds > 0)
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Time remaining: $_remainingGracePeriodSeconds seconds',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Browsers will be blocked when this time expires if the extension is not connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                ),
              ],
            ),
          ),
        if (_extensionInstallError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _extensionInstallError!,
                style: TextStyle(color: Colors.red.shade800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (!isExtensionConnected) // Use actual connection status
          _isInstallingExtension
              ? const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Opening browser to install extension...'),
                  ],
                )
              : Column(
                  children: [
                    // Browser installation buttons
                    ..._detectedBrowsers.map((browser) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.extension),
                          label: Text('Install for $browser'),
                          onPressed: () => _installBrowserExtension(browser),
                        ),
                      );
                    }).toList(),
                    
                    // Add a waiting message if installation was initiated but not connected yet
                    if (_isInstallingExtension == false && _extensionInstallError == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          children: const [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(height: 8),
                            Text(
                              'Waiting for extension to connect...',
                            ),
                          ],
                        ),
                      ),
                  ],
                )
        else
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Browser extension connected successfully!'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = _getStepTitles();
    
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: const Text(
                      'Browser Extension Setup',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // If in grace period, cancel it and go to cooldown
                      if (_startedGracePeriod) {
                        StrictModeService.instance.cancelGracePeriodWithCooldown();
                      } else {
                        widget.onSkip();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    stepTitles.length,
                    (index) => _buildStepIndicator(index, stepTitles[index]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Step title
              Text(
                stepTitles[_currentStep],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Step content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBrowserDetectionStep(),
                    _buildInstallNativeMessagingHostStep(),
                    _buildInstallExtensionStep(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // If in grace period, cancel it and go to cooldown
                      if (_startedGracePeriod) {
                        StrictModeService.instance.cancelGracePeriodWithCooldown();
                      } else {
                        widget.onSkip();
                      }
                    },
                    child: const Text('Skip Setup'),
                  ),
                  Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: _previousStep,
                          child: const Text('Back'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _getNextButtonEnabled() ? _nextStep : null,
                        child: Text(_currentStep == stepTitles.length - 1 ? 'Finish' : 'Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepIndicator(int index, String title) {
    final isActive = _currentStep >= index;
    final isCurrent = _currentStep == index;
    
    return Expanded(
      child: Row(
        children: [
          // Line before (except for first item)
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                color: isActive 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
          // Circle indicator
          GestureDetector(
            onTap: () {
              if (_currentStep > index) {
                setState(() {
                  _currentStep = index;
                });
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent 
                    ? Theme.of(context).colorScheme.primary
                    : (isActive 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant),
                border: Border.all(
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent 
                        ? Theme.of(context).colorScheme.onPrimary
                        : (isActive 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Line after (except for last item)
          if (index < _getStepTitles().length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: isActive && _currentStep > index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
  
  bool _getNextButtonEnabled() {
    switch (_currentStep) {
      case 0:
        return _detectedBrowsers.isNotEmpty;
      case 1:
        return _manifestInstalled;
      case 2:
        // Use the actual connection status from the service
        return BrowserExtensionService.instance.isExtensionConnected;
      default:
        return true;
    }
  }
}
