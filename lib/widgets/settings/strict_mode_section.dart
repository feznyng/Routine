import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../../services/strict_mode_service.dart';

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
          
          // Warning banner when in strict mode
          if (_strictModeService.inStrictMode) ...[
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
              subtitle: const Text('Prevent closing the app'),
              value: _strictModeService.blockAppExit,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockAppExit)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only allow turning on in strict mode, not turning off
                  if (_strictModeService.inStrictMode && !value) return;
                  
                  final success = await _strictModeService.setBlockAppExitWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block disabling system startup'),
              subtitle: const Text('Prevent turning off startup with system'),
              value: _strictModeService.blockDisablingSystemStartup,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockDisablingSystemStartup)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only allow turning on in strict mode, not turning off
                  if (_strictModeService.inStrictMode && !value) return;
                  
                  final success = await _strictModeService.setBlockDisablingSystemStartupWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block browsers without extension'),
              subtitle: const Text('Block browsers when extension is not installed or connected'),
              value: _strictModeService.blockBrowsersWithoutExtension,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockBrowsersWithoutExtension)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only allow turning on in strict mode, not turning off
                  if (_strictModeService.inStrictMode && !value) return;
                  
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
              subtitle: const Text('Prevent changing system time'),
              value: _strictModeService.blockChangingTimeSettings,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockChangingTimeSettings)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only allow turning on in strict mode, not turning off
                  if (_strictModeService.inStrictMode && !value) return;
                  
                  final success = await _strictModeService.setBlockChangingTimeSettingsWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block uninstalling apps'),
              subtitle: const Text('Prevent uninstalling apps'),
              value: _strictModeService.blockUninstallingApps,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockUninstallingApps)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only allow turning on in strict mode, not turning off
                  if (_strictModeService.inStrictMode && !value) return;
                  
                  final success = await _strictModeService.setBlockUninstallingAppsWithConfirmation(context, value);
                  if (success && mounted) {
                    setState(() {});
                  }
                },
            ),
            SwitchListTile(
              title: const Text('Block installing apps'),
              subtitle: const Text('Prevent installing new apps'),
              value: _strictModeService.blockInstallingApps,
              onChanged: (_strictModeService.inStrictMode && _strictModeService.blockInstallingApps)
                ? null // Disable the switch when trying to turn it off in strict mode
                : (value) async {
                  // Only allow turning on in strict mode, not turning off
                  if (_strictModeService.inStrictMode && !value) return;
                  
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
