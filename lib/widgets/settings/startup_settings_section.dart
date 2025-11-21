import 'package:routine_blocker/util.dart';
import 'package:flutter/material.dart';
import '../../services/desktop_service.dart';
import '../../services/strict_mode_service.dart';

class StartupSettingsSection extends StatefulWidget {
  const StartupSettingsSection({super.key});

  @override
  State<StartupSettingsSection> createState() => _StartupSettingsSectionState();
}

class _StartupSettingsSectionState extends State<StartupSettingsSection> {
  final _desktopService = DesktopService.instance;
  final _strictModeService = StrictModeService.instance;
  bool _startOnLogin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStartupSetting();
  }

  Future<void> _loadStartupSetting() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final startOnLogin = await _desktopService.getStartOnLogin();
      if (mounted) {
        setState(() {
          _startOnLogin = startOnLogin;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      Util.report('error loading startup setting', e, st);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Start on system startup'),
        leading: const Icon(Icons.power_settings_new),
        trailing: _isLoading 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _startOnLogin,
              onChanged: (_strictModeService.effectiveBlockDisablingSystemStartup && _startOnLogin)
                ? null  // Disable the switch completely when in strict mode
                : (value) async {
                    if (!value && _strictModeService.effectiveBlockDisablingSystemStartup) {
                      _strictModeService.showStrictModeActiveDialog(context);
                      return;
                    }
                    
                    setState(() => _isLoading = true);
                    await _desktopService.setStartOnLogin(value);
                    final result = await _desktopService.getStartOnLogin();
                    setState(() {
                      _startOnLogin = result;
                      _isLoading = false;
                    });
                  },
            ),
      ),
    );
  }
}
