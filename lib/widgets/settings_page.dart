import 'package:flutter/material.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'auth_page.dart';
import 'settings/theme_settings_section.dart';
import 'settings/startup_settings_section.dart';
import 'settings/strict_mode_section.dart';
import 'settings/device_management_section.dart';
import 'settings/auth_section.dart';
import 'settings/browser_extension_section.dart';
import 'settings/device_options_bottom_sheet.dart';
import 'settings/sync_settings_section.dart';
import 'settings/device_permissions_section.dart';
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
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Authentication section (moved to top)
          AuthSection(
            onSignInTap: _showAuthPage,
          ),
          const SizedBox(height: 16),
          
          // Theme Settings
          const ThemeSettingsSection(),
          const SizedBox(height: 16),
          
          // Start on login option (desktop only)
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[            
            const StartupSettingsSection(),
            const SizedBox(height: 16),
          ],
          
          // Strict Mode section
          const StrictModeSection(),
          const SizedBox(height: 16),
          
          // Device Management section
          DeviceManagementSection(onDeviceOptionsTap: _showDeviceOptions),
          const SizedBox(height: 16),
          
          // Browser Extension section (hidden on mobile)
          if (!isMobile) ...[  
            BrowserExtensionSection(
              onRestartOnboarding: _restartBrowserExtensionOnboarding,
            ),
            const SizedBox(height: 16),
          ],
          
          if (Platform.isIOS) ...{
            const DevicePermissionsSection(),
            const SizedBox(height: 16),
          },
          
          // Sync settings section
          const SyncSettingsSection(),
        ],
      ),
    );
  }
}


