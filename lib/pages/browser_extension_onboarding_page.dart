import 'dart:async';
import 'dart:io';
import 'package:Routine/services/browser_config.dart';
import 'package:Routine/setup.dart';
import 'package:flutter/material.dart';
import 'package:Routine/services/browser_service.dart';
import 'package:Routine/services/strict_mode_service.dart';
import 'package:Routine/widgets/browser_extension_page/browser_selection_step.dart';
import 'package:Routine/widgets/browser_extension_page/native_messaging_host_step.dart';
import 'package:Routine/widgets/browser_extension_page/extension_installation_step.dart';
import 'package:Routine/widgets/browser_extension_page/automation_permission_step.dart';
import 'package:Routine/widgets/browser_extension_page/completion_step.dart';

enum OnboardingStep {
  browserSelection,
  configuration,
  completion,
}

enum MessageType { error, success, warning, info }

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
  Map<Browser, bool> _automationPermissionMap = {};
  bool _isLoading = true;


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
    
    await _browserExtensionService.initializeControllableBrowsers();
 
    // Get installed browsers
    final browsers = (await _browserExtensionService.getInstalledSupportedBrowsers(connected: null))
      .map((b) => b.browser).toList();
    
    // Initialize NMH installation status map for each browser
    Map<Browser, bool> nmhMap = {};
    Map<Browser, bool> automationMap = {};
    for (final browser in browsers) {
      nmhMap[browser] = false;
      automationMap[browser] = false;
    }
    
    setState(() {
      _installedBrowsers = browsers;
      // Only select unconnected browsers by default
      _selectedBrowsers = browsers.where(
        (b) => !_browserExtensionService.isBrowserConnected(b)
      ).toList();
      _nmhInstalledMap = nmhMap;
      _automationPermissionMap = automationMap;
      _isLoading = false;
    });
  }

  void _updateConnectionStatus() {
    // Trigger a rebuild to update the _canProceed() evaluation
    // This ensures the Next button is enabled/disabled based on current connection status
    if (mounted) {
      setState(() {
        // No state changes needed, just trigger rebuild
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
    
    final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
    final browserConfig = browserData[currentBrowser]!;
    
    // Check if this is a macOS controllable browser
    if (Platform.isMacOS && browserConfig.macosControllable) {
      // For macOS controllable browsers, we only need automation permission
      if (_currentStep == 1) {
        // Check if automation permission is granted
        if (!(_automationPermissionMap[currentBrowser] ?? false)) {
          setState(() {
            _errorMessage = 'Please grant automation permission first';
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
        
        // Otherwise, stay on step 1 for the next browser
        setState(() {
          // Stay on step 1 for next browser
        });
        return;
      }
    } else {
      // For extension-based browsers, follow the original flow
      if (_currentStep == 1) {
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

  void _finish() {
    if (!_browserExtensionService.endGracePeriod()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        title: Row(
          children: [
            Icon(
              Icons.extension_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Browser Extension Setup'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleBackNavigation(context),
          tooltip: 'Close setup',
        ),
        titleSpacing: 16,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Detecting installed browsers...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              constraints: const BoxConstraints(maxWidth: 800),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Error/Warning messages
                  if (_errorMessage != null)
                    _buildMessage(
                      type: MessageType.error,
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                  
                  // Grace period warning (hide if extension is connected or on completion page)
                  if (_inGracePeriod && _remainingSeconds > 0 && _shouldShowGracePeriodWarning())
                    _buildMessage(
                      type: MessageType.warning,
                      message: 'Grace period active: ${_remainingSeconds}s remaining. '
                             'Complete setup before time expires to avoid browser blocking.',
                    ),
                  
                  // Main step content
                  Expanded(
                    child: _buildCurrentStep(),
                  ),
                  
                  // Navigation actions
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
          onSelectionChanged: (browsers) {
            setState(() {
              _selectedBrowsers = browsers;
            });
          },
          onErrorChanged: (error) {
            setState(() {
              _errorMessage = error;
            });
          },
        );
      case 1:
        if (_currentBrowserIndex < _selectedBrowsers.length) {
          final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
          final browserConfig = browserData[currentBrowser]!;
          
          // Check if this is a macOS controllable browser
          if (Platform.isMacOS && browserConfig.macosControllable) {
            return AutomationPermissionStep(
              browser: currentBrowser,
              onPermissionChanged: (browser, hasPermission) {
                setState(() {
                  _automationPermissionMap[browser] = hasPermission;
                });
              },
              onErrorChanged: (error) {
                setState(() {
                  _errorMessage = error;
                });
              },
              totalBrowsers: _selectedBrowsers.length,
              currentBrowserIndex: _currentBrowserIndex,
            );
          } else {
            // For extension-based browsers, show NMH step
            return NativeMessagingHostStep(
              browser: currentBrowser,
              onInstallationChanged: (browser, installed) {
                setState(() {
                  _nmhInstalledMap[browser] = installed;
                });
              },
              onErrorChanged: (error) {
                setState(() {
                  _errorMessage = error;
                });
              },
              totalBrowsers: _selectedBrowsers.length,
              currentBrowserIndex: _currentBrowserIndex,
            );
          }
        }
        return const Center(child: Text('No browsers selected'));
      case 2:
        if (_currentBrowserIndex < _selectedBrowsers.length) {
          final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
          
          return ExtensionInstallationStep(
            browser: currentBrowser,
            onInstallRequested: (browser) {
              _startConnectionAttemptTimer();
            },
            onErrorChanged: (error) {
              setState(() {
                _errorMessage = error;
              });
            },
            inGracePeriod: _inGracePeriod,
            remainingSeconds: _remainingSeconds,
            totalBrowsers: _selectedBrowsers.length,
            currentBrowserIndex: _currentBrowserIndex,
          );
        }
        return const Center(child: Text('No browsers selected'));
      case 3:
        return CompletionStep(
          connectedBrowsers: _selectedBrowsers,
        );
      default:
        return const Center(child: Text('Unknown step'));
    }
  }

  bool _shouldShowGracePeriodWarning() {
    // Hide grace period warning on completion page
    if (_currentStep == 3) {
      return false;
    }
    
    // Hide grace period warning on extension installation step (it shows its own timer)
    if (_currentStep == 2) {
      return false;
    }
    
    return true;
  }

  Widget _buildMessage({
    required MessageType type,
    required String message,
    VoidCallback? onDismiss,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    IconData iconData;
    
    switch (type) {
      case MessageType.error:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        borderColor = colorScheme.error;
        iconData = Icons.error_outline_rounded;
        break;
      case MessageType.warning:
        backgroundColor = Colors.amber.withOpacity(0.1);
        foregroundColor = Colors.amber[800]!;
        borderColor = Colors.amber;
        iconData = Icons.warning_amber_rounded;
        break;
      case MessageType.success:
        backgroundColor = colorScheme.primaryContainer;
        foregroundColor = colorScheme.onPrimaryContainer;
        borderColor = colorScheme.primary;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case MessageType.info:
        backgroundColor = colorScheme.surfaceVariant;
        foregroundColor = colorScheme.onSurfaceVariant;
        borderColor = colorScheme.outline;
        iconData = Icons.info_outline_rounded;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: foregroundColor,
              onPressed: onDismiss,
              tooltip: 'Dismiss',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentStep > 0 && _currentStep < 3)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          
          // Next/Finish button
          if (_currentStep < 3)
            FilledButton.icon(
              onPressed: _canProceed() ? _nextStep : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_getNextButtonLabel()),
            )
          else
            FilledButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Finish Setup'),
            ),
        ],
      ),
    );
  }
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedBrowsers.isNotEmpty;
      case 1:
        if (_currentBrowserIndex < _selectedBrowsers.length) {
          final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
          final browserConfig = browserData[currentBrowser]!;
          
          if (Platform.isMacOS && browserConfig.macosControllable) {
            return _automationPermissionMap[currentBrowser] ?? false;
          } else {
            return _nmhInstalledMap[currentBrowser] ?? false;
          }
        }
        return false;
      case 2:
        if (_currentBrowserIndex < _selectedBrowsers.length) {
          final currentBrowser = _selectedBrowsers[_currentBrowserIndex];
          return _browserExtensionService.isBrowserConnected(currentBrowser);
        }
        return false;
      default:
        return true;
    }
  }
  
  String _getNextButtonLabel() {
    switch (_currentStep) {
      case 0:
        return 'Continue';
      case 1:
        return 'Next';
      case 2:
        return 'Next';
      default:
        return 'Continue';
    }
  }
}
