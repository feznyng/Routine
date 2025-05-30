import 'dart:async';
import 'package:Routine/services/browser_config.dart';
import 'package:Routine/setup.dart';
import 'package:flutter/material.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:Routine/services/strict_mode_service.dart';
import 'package:Routine/widgets/browser_extension_page/browser_selection_step.dart';
import 'package:Routine/widgets/browser_extension_page/native_messaging_host_step.dart';
import 'package:Routine/widgets/browser_extension_page/extension_installation_step.dart';
import 'package:Routine/widgets/browser_extension_page/completion_step.dart';

enum MessageType { error, success }

class BrowserExtensionOnboardingPage extends StatefulWidget {
  final bool inGracePeriod;

  const BrowserExtensionOnboardingPage({
    super.key,
    this.inGracePeriod = false,
  });

  @override
  State<BrowserExtensionOnboardingPage> createState() => _BrowserExtensionOnboardingPageState();
}

class _BrowserExtensionOnboardingPageState extends State<BrowserExtensionOnboardingPage> {
  final BrowserService _browserExtensionService = BrowserService.instance;
  final StrictModeService _strictModeService = StrictModeService.instance;
  
  int _currentStep = 0;
  List<Browser> _installedBrowsers = [];
  List<Browser> _selectedBrowsers = [];
  int _currentBrowserIndex = 0;
  Map<Browser, bool> _nmhInstalledMap = {};
  bool _isLoading = true;
  bool _isExtensionConnecting = false;
  String? _errorMessage;
  
  // Grace period related variables
  bool _inGracePeriod = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  StreamSubscription? _gracePeriodExpirationListener;
  
  // Connection attempt timer
  Timer? _connectionAttemptTimer;
  StreamSubscription? _connectionStatusSubscription;

  @override
  void initState() {
    super.initState();
    _inGracePeriod = widget.inGracePeriod;
    _loadInstalledBrowsers();
    
    // Listen for connection status changes
    _connectionStatusSubscription = _browserExtensionService.connectionStream.listen((connected) {
      _updateConnectionStatus();
    });
    
    _gracePeriodExpirationListener = _browserExtensionService.gracePeriodStream.listen((started) {
      if (!started) {
        _onGracePeriodExpired();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _connectionAttemptTimer?.cancel();
    _connectionStatusSubscription?.cancel();
    _gracePeriodExpirationListener?.cancel();
    super.dispose();
  }

  Future<void> _loadInstalledBrowsers() async {
    setState(() {
      _isLoading = true;
    });
    
    // Get installed browsers
    final browsers = (await _browserExtensionService.getInstalledSupportedBrowsers())
      .map((b) => b.browser).toList();
    
    // Initialize NMH installation status map for each browser
    Map<Browser, bool> nmhMap = {};
    for (final browser in browsers) {
      nmhMap[browser] = false;
    }
    
    setState(() {
      _installedBrowsers = browsers;
      // Only select unconnected browsers by default
      _selectedBrowsers = browsers.where(
        (b) => !_browserExtensionService.isBrowserConnected(b)
      ).toList();
      _nmhInstalledMap = nmhMap;
      _isLoading = false;
    });
  }

  void _updateConnectionStatus() {
    if (_currentStep == 2 && _currentBrowserIndex < _selectedBrowsers.length) {
      final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
      final isConnected = _browserExtensionService.isBrowserConnected(currentBrowser);
      
      setState(() {
        if (isConnected) {
          _isExtensionConnecting = false;
        }
      });
    }
  }

  void _onGracePeriodExpired() {
    logger.i("onGracePeriodExpired");
    if (mounted) Navigator.of(context).pop();
  }

  void _startConnectionAttemptTimer() {
    // Cancel any existing timer
    _connectionAttemptTimer?.cancel();
    
    // Start a new timer that attempts to connect every 2 seconds
    _connectionAttemptTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentBrowserIndex < _selectedBrowsers.length) {
        // No need to connect since we're in server mode
      } else {
        // Stop the timer if we've gone through all browsers
        timer.cancel();
      }
    });
  }

  void _startGracePeriodCountdown() {
    logger.i("check and starting grace period ${_strictModeService.effectiveBlockBrowsersWithoutExtension}");

    if (_strictModeService.effectiveBlockBrowsersWithoutExtension) {
      logger.i("starting grace period");

      final gracePeriodDuration = 60;
      
      _browserExtensionService.startGracePeriod(gracePeriodDuration);
      
      setState(() {
        _inGracePeriod = true;
        _remainingSeconds = gracePeriodDuration;
      });
      
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  void _nextStep() {
    // Clear any existing error message when moving to next step
    setState(() {
      _errorMessage = null;
    });
    
    if (_currentStep == 0 && _selectedBrowsers.isEmpty) {
      // Can't proceed if no browsers are selected
      setState(() {
        _errorMessage = 'Please select at least one browser';
      });
      return;
    }
    
    if (_currentStep == 0) {
      _currentBrowserIndex = 0;
      setState(() {
        _currentStep++;
      });
      return;
    }
    
    if (_currentStep == 1) {
      final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
      if (!(_nmhInstalledMap[currentBrowser] ?? false)) {
        setState(() {
          _errorMessage = 'Please install the Native Messaging Host first';
        });
        return;
      }
      
      _startConnectionAttemptTimer();
      _startGracePeriodCountdown();
      
      setState(() {
        _currentStep++;
      });

      return;
    }
    
    if (_currentStep == 2) {

      final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
      final isConnected = _browserExtensionService.isBrowserConnected(currentBrowser);
      
      if (!isConnected) {
        setState(() {
          _errorMessage = 'Please wait for the extension to connect';
        });
        return;
      }
      
      // Move to the next browser or to the completion step
      _currentBrowserIndex++;
      
      // If we've gone through all browsers, move to the completion step
      if (_currentBrowserIndex >= _selectedBrowsers.length) {
        setState(() {
          _currentStep = 3; // Completion step
        });
        return;
      }
      
      // Otherwise, go back to the NMH installation step for the next browser
      setState(() {
        _currentStep = 1; // Back to NMH installation for next browser
      });
      return;
    }
    
    // For any other steps, just increment
    setState(() {
      _currentStep++;
    });
  }

  Future<void> _handleBackNavigation(BuildContext context) async {
    if (_inGracePeriod) {
      final shouldGoBack = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Warning'),
            ],
          ),
          content: const Text(
            'Since strict mode is enabled, exiting now will trigger a 10-minute cooldown period. '
            'During this time, you won\'t be able to set up the browser extension again and browsers will remain block.\n\n'
            'Are you sure you want to exit?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit Anyway'),
            ),
          ],
        )

      );

      if (shouldGoBack == true) {
        _browserExtensionService.endGracePeriod();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        
        // If going back from extension installation to NMH installation,
        // reset the current browser index
        if (_currentStep == 1) {
          _currentBrowserIndex = 0;
        }
      });
    }
  }

  void _toggleBrowserSelection(Browser browser) {
    setState(() {
      if (_selectedBrowsers.contains(browser)) {
        _selectedBrowsers.remove(browser);
      } else {
        _selectedBrowsers.add(browser);
      }
    });
  }

  void _installNativeMessagingHost() async {
    if (_currentBrowserIndex < _selectedBrowsers.length) {
      final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
      
      setState(() {
        _isLoading = true;
      });
      
      // Install NMH - note that the current API doesn't support per-browser installation
      // but the UI will track it per browser for a better user experience
      final success = await _browserExtensionService.installNativeMessagingHost(currentBrowser);
      
      setState(() {
        _nmhInstalledMap[currentBrowser] = success;
        _isLoading = false;
      });
      
      if (!success) {
        setState(() {
          _errorMessage = 'Failed to install native messaging host for $currentBrowser';
        });
      }
    }
  }

  void _installBrowserExtension() async {
    if (_currentBrowserIndex < _selectedBrowsers.length) {
      final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
      
      setState(() {
        _isExtensionConnecting = true;
      });
      
      await _browserExtensionService.installBrowserExtension(currentBrowser);
      
      // Start connection attempt timer
      _startConnectionAttemptTimer();
    }
  }

  void _finish() {
    if (!_browserExtensionService.endGracePeriod()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browser Extension Setup'),
        leading: _currentStep == 3 ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              constraints: const BoxConstraints(maxWidth: 800),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildCurrentStep(),
                  ),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () => setState(() {
                              _errorMessage = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  _buildActions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return BrowserSelectionStep(
          installedBrowsers: _installedBrowsers,
          selectedBrowsers: _selectedBrowsers,
          onToggleBrowser: _toggleBrowserSelection,
        );
      case 1:
        if (_currentBrowserIndex < _selectedBrowsers.length) {
          final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
          final nmhInstalled = _nmhInstalledMap[currentBrowser] ?? false;
          
          return NativeMessagingHostStep(
            browser: currentBrowser,
            nmhInstalled: nmhInstalled,
            onInstall: _installNativeMessagingHost,
            totalBrowsers: _selectedBrowsers.length,
            currentBrowserIndex: _currentBrowserIndex,
          );
        }
        return const Center(child: Text('No browsers selected'));
      case 2:
        if (_currentBrowserIndex < _selectedBrowsers.length) {
          final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
          final isConnected = _browserExtensionService.isBrowserConnected(currentBrowser);
          
          return ExtensionInstallationStep(
            browser: currentBrowser,
            isConnected: isConnected,
            isConnecting: _isExtensionConnecting,
            onInstall: _installBrowserExtension,
            inGracePeriod: _inGracePeriod,
            remainingSeconds: _remainingSeconds,
            totalBrowsers: _selectedBrowsers.length,
            currentBrowserIndex: _currentBrowserIndex,
          );
        }
        return const Center(child: Text('No browsers selected'));
      case 3:
        return CompletionStep(
          connectedBrowsers: _browserExtensionService.connectedBrowsers,
        );
      default:
        return const Center(child: Text('Unknown step'));
    }
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0 && _currentStep < 3)
          TextButton(
            onPressed: _previousStep,
            child: const Text('Back'),
          )
        else
          const SizedBox.shrink(),
        if (_currentStep < 3)
          ElevatedButton(
            onPressed: _nextStep,
            child: Text(_currentStep == 2 ? 'Next' : 'Continue'),
          )
        else
          ElevatedButton(
            onPressed: _finish,
            child: const Text('Finish'),
          ),
      ],
    );
  }
}
