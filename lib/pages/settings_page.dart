import 'package:Routine/util.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'auth_page.dart';
import '../widgets/settings/theme_settings_section.dart';
import '../widgets/settings/startup_settings_section.dart';
import '../widgets/settings/strict_mode_section.dart';
import '../widgets/settings/device_management_section.dart';
import '../widgets/settings/auth_section.dart';
import '../widgets/settings/browser_section.dart';
import '../widgets/settings/device_options_bottom_sheet.dart';
import '../widgets/settings/sync_settings_section.dart';
import '../widgets/settings/device_permissions_section.dart';
import '../widgets/settings/feedback_section.dart';
import '../models/device.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showAuthPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AuthPage(),
      ),
    );
  }
  
  void _showDeviceOptions(Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DeviceOptionsBottomSheet(device: device),
    );
  }
  
  Future<void> _restartBrowserExtensionOnboarding() async {
    // Force refresh the state
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Util.isDesktop();
    
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          AuthSection(
            onSignInTap: _showAuthPage,
          ),
          const SizedBox(height: 16),
          
          const ThemeSettingsSection(),
          const SizedBox(height: 16),
          
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[            
            const StartupSettingsSection(),
            const SizedBox(height: 16),
          ],
          
          const StrictModeSection(),
          const SizedBox(height: 16),
          
          DeviceManagementSection(onDeviceOptionsTap: _showDeviceOptions),
          const SizedBox(height: 16),
          
          if (isDesktop) ...[  
            BrowserSection(
              onRestartOnboarding: _restartBrowserExtensionOnboarding,
            ),
            const SizedBox(height: 16),
          ] else ...{
            const DevicePermissionsSection(),
            const SizedBox(height: 16),
          },
          
          const SyncSettingsSection(),
          const SizedBox(height: 16),
          
          const FeedbackSection(),
        ],
      ),
    );
  }
}


