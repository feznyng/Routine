import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../../services/mobile_service.dart';

class DevicePermissionsSection extends StatefulWidget {
  const DevicePermissionsSection({super.key});

  @override
  State<DevicePermissionsSection> createState() => _DevicePermissionsSectionState();
}

class _DevicePermissionsSectionState extends State<DevicePermissionsSection> {
  bool _notificationPermission = false;
  bool _cameraPermission = false;
  bool _locationPermission = false;
  bool _familyControlsPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    // Check notifications permission
    final notificationStatus = await Permission.notification.status;
    
    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    
    // Check location permission
    final locationStatus = await Permission.location.status;
    
    // Check family controls authorization
    final familyControlsStatus = await MobileService.instance.checkFamilyControlsAuthorization();

    if (!mounted) return;

    setState(() {
      _notificationPermission = notificationStatus.isGranted;
      _cameraPermission = cameraStatus.isGranted;
      _locationPermission = locationStatus.isGranted;
      _familyControlsPermission = familyControlsStatus;
    });
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onOpenSettings,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isGranted
          ? const Icon(Icons.check_circle, color: Colors.green)
          : TextButton(
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Permissions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPermissionTile(
              title: 'Notifications',
              subtitle: 'Required to keep routines updated in the background',
              isGranted: _notificationPermission,
              onOpenSettings: () => AppSettings.openAppSettings(type: AppSettingsType.notification),
            ),
            const Divider(),
            _buildPermissionTile(
              title: 'Camera',
              subtitle: 'Required for scanning QR codes',
              isGranted: _cameraPermission,
              onOpenSettings: () => AppSettings.openAppSettings(type: AppSettingsType.camera),
            ),
            const Divider(),
            _buildPermissionTile(
              title: 'Location',
              subtitle: 'Required for creating and completing location conditions',
              isGranted: _locationPermission,
              onOpenSettings: () => AppSettings.openAppSettings(type: AppSettingsType.location),
            ),
            const Divider(),
            _buildPermissionTile(
              title: 'Screen Time Restrictions',
              subtitle: 'Required to block apps and websites',
              isGranted: _familyControlsPermission,
              onOpenSettings: () => AppSettings.openAppSettings(type: AppSettingsType.notification), // will redirect to same page
            ),
          ],
        ),
      ),
    );
  }
}
