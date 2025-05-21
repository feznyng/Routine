import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../../services/strict_mode_service.dart';
import '../common/emergency_mode_banner.dart';

class StrictModeSection extends StatefulWidget {
  const StrictModeSection({super.key});

  @override
  State<StrictModeSection> createState() => _StrictModeSectionState();
}

class _StrictModeSectionState extends State<StrictModeSection> {
  final _strictModeService = StrictModeService.instance;
  Timer? _gracePeriodTimer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _strictModeService.init().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Listen for changes to strict mode service
    _strictModeService.addListener(_onStrictModeServiceChanged);
    
    // Start timers if needed
    _startTimersIfNeeded();
  }
  
  void _onStrictModeServiceChanged() {
    if (mounted) {
      setState(() {});
      _startTimersIfNeeded();
    }
  }
  
  void _startTimersIfNeeded() {
    // Cancel existing timers
    _gracePeriodTimer?.cancel();
    _cooldownTimer?.cancel();
    
    // Start grace period timer if in grace period
    if (_strictModeService.isInExtensionGracePeriod) {
      _gracePeriodTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_strictModeService.isInExtensionGracePeriod) {
          timer.cancel();
        }
        if (mounted) {
          setState(() {});
        }
      });
    }
    
    // Start cooldown timer if in cooldown
    if (_strictModeService.isInExtensionCooldown) {
      _cooldownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (!_strictModeService.isInExtensionCooldown) {
          timer.cancel();
        }
        if (mounted) {
          setState(() {});
        }
      });
    }
  }
  
  @override
  void dispose() {
    _strictModeService.removeListener(_onStrictModeServiceChanged);
    _gracePeriodTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Strict Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          
          // Emergency mode button and banner
          if (_strictModeService.inStrictMode || _strictModeService.emergencyMode) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _strictModeService.emergencyMode || _strictModeService.canStartEmergency
                    ? () async {
                        final newValue = !_strictModeService.emergencyMode;
                        
                        if (newValue) {
                          // Show confirmation dialog for enabling emergency mode
                          final remainingEmergencies = _strictModeService.remainingEmergencies;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Enable Emergency Mode'),
                              content: Text(
                                'This will suspend all strict mode restrictions until you disable it. '
                                'You have $remainingEmergencies emergenc${remainingEmergencies == 1 ? 'y' : 'ies'} '
                                'remaining.\n\n'
                                'Are you sure you want to proceed?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Enable Emergency Mode'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm != true) return;
                        } else {
                          // Show confirmation dialog for disabling emergency mode
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('End Emergency Mode'),
                              content: Text(
                                'This will re-enable all strict mode restrictions.\n\n'
                                'You will have ${_strictModeService.remainingEmergencies} emergenc${_strictModeService.remainingEmergencies == 1 ? 'y' : 'ies'} '
                                'remaining this week.\n\n'
                                'Are you sure you want to proceed?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.amber,
                                  ),
                                  child: const Text('End Emergency Mode'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm != true) return;
                        }
                        
                        await _strictModeService.setEmergencyMode(newValue);
                        if (mounted) setState(() {});
                      }
                    : null,
                icon: Icon(
                  _strictModeService.emergencyMode ? Icons.warning_amber : Icons.emergency,
                  color: _strictModeService.emergencyMode ? Colors.amber : Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: _strictModeService.emergencyMode ? BorderSide(color: Colors.amber) : null,
                ),
                label: Text(_strictModeService.emergencyMode ? 'End Emergency Mode' : 'Enable Emergency Mode'),
              ),
            ),

            // Show emergency limit message if needed
            if (!_strictModeService.emergencyMode && !_strictModeService.canStartEmergency)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'You have reached the limit of 2 emergencies per week',
                  style: TextStyle(color: Colors.amber[800], fontSize: 14),
                ),
              ),

            // Show emergency mode banner if emergency mode is active, otherwise show strict mode warning if in strict mode
            if (_strictModeService.emergencyMode)
              const EmergencyModeBanner()
            else if (_strictModeService.inStrictMode)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Strict Mode Active',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'A routine with strict mode is currently active. You cannot disable strict mode settings until all strict mode routines become inactive.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          
          // Desktop strict mode options
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
            SwitchListTile(
              title: const Text('Block app exit'),
              value: _strictModeService.blockAppExit,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockAppExit && !_strictModeService.emergencyMode)
                ? null // Disable the switch when trying to turn it off in strict mode (unless in emergency mode)
                : (value) async {
                  // Only prevent turning off in strict mode when not in emergency mode
                  if (_strictModeService.inStrictMode && !value && !_strictModeService.emergencyMode) return;
                  
                  final success = await _strictModeService.setBlockAppExitWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block disabling system startup'),
              value: _strictModeService.blockDisablingSystemStartup,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockDisablingSystemStartup && !_strictModeService.emergencyMode)
                ? null // Disable the switch when trying to turn it off in strict mode (unless in emergency mode)
                : (value) async {
                  // Only prevent turning off in strict mode when not in emergency mode
                  if (_strictModeService.inStrictMode && !value && !_strictModeService.emergencyMode) return;
                  
                  final success = await _strictModeService.setBlockDisablingSystemStartupWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block browsers without extension'),
              value: _strictModeService.blockBrowsersWithoutExtension,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockBrowsersWithoutExtension && !_strictModeService.emergencyMode)
                ? null // Disable the switch when trying to turn it off in strict mode (unless in emergency mode)
                : (value) async {
                  // Only prevent turning off in strict mode when not in emergency mode
                  if (_strictModeService.inStrictMode && !value && !_strictModeService.emergencyMode) return;
                  
                  final success = await _strictModeService.setBlockBrowsersWithoutExtensionWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            )
          ],
          
          // iOS strict mode options
          if (Platform.isIOS) ...[
            SwitchListTile(
              title: const Text('Block changing time settings'),
              value: _strictModeService.blockChangingTimeSettings,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockChangingTimeSettings && !_strictModeService.emergencyMode)
                ? null // Disable the switch when trying to turn it off in strict mode (unless in emergency mode)
                : (value) async {
                  // Only prevent turning off in strict mode when not in emergency mode
                  if (_strictModeService.inStrictMode && !value && !_strictModeService.emergencyMode) return;
                  
                  final success = await _strictModeService.setBlockChangingTimeSettingsWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block uninstalling apps'),
              value: _strictModeService.blockUninstallingApps,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockUninstallingApps)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only prevent turning off in strict mode when not in emergency mode
                  if (_strictModeService.inStrictMode && !value && !_strictModeService.emergencyMode) return;
                  
                  final success = await _strictModeService.setBlockUninstallingAppsWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block installing apps'),
              value: _strictModeService.blockInstallingApps,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockInstallingApps)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only prevent turning off in strict mode when not in emergency mode
                  if (_strictModeService.inStrictMode && !value && !_strictModeService.emergencyMode) return;
                  
                  final success = await _strictModeService.setBlockInstallingAppsWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
          ],
        ],
      ),
    );
  }
}
