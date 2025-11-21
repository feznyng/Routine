import 'package:routine_blocker/util.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../../services/strict_mode_service.dart';
import '../../services/browser_service.dart';
import '../common/emergency_mode_banner.dart';

class StrictModeSection extends StatefulWidget {
  const StrictModeSection({super.key});

  @override
  State<StrictModeSection> createState() => _StrictModeSectionState();
}

class _StrictModeSectionState extends State<StrictModeSection> {
  final _strictModeService = StrictModeService.instance;
  final _browserService = BrowserService.instance;
  Timer? _gracePeriodTimer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    
    _strictModeService.addListener(_onStrictModeServiceChanged);
    _startTimersIfNeeded();
  }
  
  void _onStrictModeServiceChanged() {
    if (mounted) {
      setState(() {});
      _startTimersIfNeeded();
    }
  }
  
  void _startTimersIfNeeded() {
    _gracePeriodTimer?.cancel();
    _cooldownTimer?.cancel();
    if (_browserService.isInGracePeriod) {
      _gracePeriodTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_browserService.isInGracePeriod) {
          timer.cancel();
        }
        if (mounted) {
          setState(() {});
        }
      });
    }
    if (_browserService.isInCooldown) {
      _cooldownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (!_browserService.isInCooldown) {
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
          if (_strictModeService.inStrictMode || _strictModeService.emergencyMode) ...[  
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
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
            SwitchListTile(
              title: const Text('Block app exit'),
              value: _strictModeService.blockAppExit,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockAppExit && !_strictModeService.emergencyMode)
                ? null // Disable the switch when trying to turn it off in strict mode (unless in emergency mode)
                : (value) async {
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
                  if (_strictModeService.inStrictMode && !value && !_strictModeService.emergencyMode) return;
                  
                  final success = await _strictModeService.setBlockBrowsersWithoutExtensionWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            )
          ],
          if (!Util.isDesktop()) ...[            SwitchListTile(
              title: const Text('Block changing time settings'),
              value: _strictModeService.blockChangingTimeSettings,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockChangingTimeSettings && !_strictModeService.emergencyMode)
                ? null // Disable the switch when trying to turn it off in strict mode (unless in emergency mode)
                : (value) async {
                  final success = await _strictModeService.setBlockChangingTimeSettingsWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: Text('Block uninstalling ${Platform.isAndroid ? 'Routine' : 'apps'}'),
              value: _strictModeService.blockUninstallingApps,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockUninstallingApps)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
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
                  final success = await _strictModeService.setBlockInstallingAppsWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
          ],
          if (_strictModeService.inStrictMode || _strictModeService.emergencyMode) ...[
            const Divider(height: 1),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    const Text('Emergency Mode'),
                  ],
                ),
                subtitle: !_strictModeService.canStartEmergency && !_strictModeService.emergencyMode
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        'You have reached the limit of 2 emergencies per week',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  : null,
                isThreeLine: !_strictModeService.canStartEmergency && !_strictModeService.emergencyMode,
                value: _strictModeService.emergencyMode,
                activeColor: Colors.amber,
                activeTrackColor: Colors.amber.withOpacity(0.5),
                onChanged: _strictModeService.emergencyMode || _strictModeService.canStartEmergency
                  ? (value) async {
                      if (value) {
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
                                  foregroundColor: Colors.amber,
                                ),
                                child: const Text('Enable Emergency Mode'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm != true) return;
                      } else {
                        final numEmergenciesLeft = _strictModeService.remainingEmergencies;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('End Emergency Mode'),
                            content: Text(
                              'This will re-enable all strict mode restrictions.\n\n'
                              'You will have $numEmergenciesLeft emergenc${numEmergenciesLeft == 1 ? 'y' : 'ies'} '
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
                      
                      await _strictModeService.setEmergencyMode(value);
                      if (mounted) setState(() {});
                    }
                  : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
