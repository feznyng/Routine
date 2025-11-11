import 'dart:async';
import 'package:Routine/setup.dart';
import 'package:flutter/material.dart';
import '../services/mobile_service.dart';

class AndroidPermissionsOnboardingDialog extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const AndroidPermissionsOnboardingDialog({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<AndroidPermissionsOnboardingDialog> createState() => _AndroidPermissionsOnboardingDialogState();
}

class _AndroidPermissionsOnboardingDialogState extends State<AndroidPermissionsOnboardingDialog> with WidgetsBindingObserver {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _hasOverlayPermission = false;
  bool _hasAccessibilityPermission = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }
  

  bool get _needsOnlyOnePermission {
    return (_hasOverlayPermission && !_hasAccessibilityPermission) || 
           (!_hasOverlayPermission && _hasAccessibilityPermission);
  }
  

  List<String> _getStepTitles() {
    if (_needsOnlyOnePermission) {
      if (_hasOverlayPermission) {
        return ['Accessibility Service'];
      }
      return ['Display Over Other Apps'];
    }
    return [
      'Display Over Other Apps',
      'Accessibility Service',
    ];
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logger.i("detected app resume");
      _checkPermissions();
    }
  }
  
  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final mobileService = MobileService();
      _hasOverlayPermission = await mobileService.checkOverlayPermission();
      _hasAccessibilityPermission = await mobileService.checkAccessibilityPermission();
      if (_hasOverlayPermission && _hasAccessibilityPermission) {
        widget.onComplete();
        return;
      }
      setState(() {
        if (_hasOverlayPermission && !_hasAccessibilityPermission) {
          _currentStep = _needsOnlyOnePermission ? 0 : 1;
          _pageController.jumpToPage(_currentStep);
        }
      });
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _requestOverlayPermission() async {
    try {
      final mobileService = MobileService();
      await mobileService.requestOverlayPermission();
      await Future.delayed(const Duration(seconds: 1));
      _hasOverlayPermission = await mobileService.checkOverlayPermission();
      
      setState(() {});
      if (_hasOverlayPermission) {
        _nextStep();
      }
    } catch (e) {
    }
  }
  
  Future<void> _requestAccessibilityPermission() async {
    try {
      final mobileService = MobileService();
      await mobileService.requestAccessibilityPermission();
      await Future.delayed(const Duration(seconds: 1));
      _hasAccessibilityPermission = await mobileService.checkAccessibilityPermission();
      
      setState(() {});
      if (_hasAccessibilityPermission) {
        widget.onComplete();
      }
    } catch (e) {
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
    } else {
      widget.onComplete();
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
  

  
  Widget _buildOverlayPermissionStep() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Icon(
            Icons.layers_outlined,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Display Over Other Apps',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Routine needs permission to display over other apps to effectively block websites and applications.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'When you tap "Grant Permission", you\'ll be taken to the Display Over Other Apps settings. Please enable "Routine" in the list of apps.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (!_hasOverlayPermission)
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
              onPressed: _requestOverlayPermission,
            )
          else
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Permission Granted!'),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildAccessibilityPermissionStep() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Icon(
            Icons.accessibility_new,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Accessibility Service Permission',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Routine needs accessibility service permission to monitor and block applications and websites.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'When you tap "Grant Permission", you\'ll be taken to the Accessibility settings. Please enable "Routine" in the list of services.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (!_hasAccessibilityPermission)
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
              onPressed: _requestAccessibilityPermission,
            )
          else
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Permission Granted!'),
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Android Permissions Setup',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onSkip,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!_needsOnlyOnePermission) ...[  
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
              ],
              Text(
                stepTitles[_currentStep],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _needsOnlyOnePermission
                    ? [
                        _hasOverlayPermission
                          ? _buildAccessibilityPermissionStep()
                          : _buildOverlayPermissionStep(),
                      ]
                    : [
                        _buildOverlayPermissionStep(),
                        _buildAccessibilityPermissionStep(),
                      ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onSkip,
                    child: const Text('Cancel'),
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
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                color: isActive 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
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
    if (_needsOnlyOnePermission) {
      if (_hasOverlayPermission) {
        return _hasAccessibilityPermission;
      }
      return _hasOverlayPermission;
    }
    switch (_currentStep) {
      case 0:
        return _hasOverlayPermission;
      case 1:
        return _hasAccessibilityPermission;
      default:
        return true;
    }
  }
}
