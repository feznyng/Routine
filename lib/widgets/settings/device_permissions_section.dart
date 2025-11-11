import 'dart:async';
import 'dart:io';

import 'package:Routine/services/mobile_service.dart';
import 'package:Routine/setup.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../android_permissions_onboarding_dialog.dart';

class DevicePermissionsSection extends StatefulWidget {
  const DevicePermissionsSection({super.key});

  @override
  State<DevicePermissionsSection> createState() => _DevicePermissionsSectionState();
}

class _DevicePermissionsSectionState extends State<DevicePermissionsSection> with WidgetsBindingObserver {
  bool _notificationPermission = false;
  bool _cameraPermission = false;
  bool _locationPermission = false;
  bool _blockPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    final notificationStatus = await Permission.notification.status;    
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    
    final blockStatus = await MobileService.instance.getBlockPermissions();

    logger.i("block perms = $blockStatus");

    if (!mounted) return;

    setState(() {
      _notificationPermission = notificationStatus.isGranted;
      _cameraPermission = cameraStatus.isGranted;
      _locationPermission = locationStatus.isGranted;
      _blockPermission = blockStatus;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (mounted) {
      await _checkPermissions();
    }
    if (!status.isGranted) {
      if (mounted) {
        AppSettings.openAppSettings(type: _getSettingsType(permission));
      }
    }
  }

  Future<void> _requestBlockPermissions() async {
    if (Platform.isIOS) {
      final granted = await MobileService.instance.getBlockPermissions(request: true);
      if (mounted) {
        await _checkPermissions();
      }
      if (!granted && mounted) {
        AppSettings.openAppSettings(type: AppSettingsType.settings);  // iOS will redirect to Screen Time settings
      }
    } else if (Platform.isAndroid) {
      final mobileService = MobileService.instance;
      final hasOverlay = await mobileService.checkOverlayPermission();
      final hasAccessibility = await mobileService.checkAccessibilityPermission();
      if (!hasOverlay || !hasAccessibility) {
        if (!mounted) return;
        
        final completer = Completer<bool>();
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AndroidPermissionsOnboardingDialog(
            onComplete: () {
              Navigator.of(dialogContext).pop();
              completer.complete(true);
            },
            onSkip: () {
              Navigator.of(dialogContext).pop();
              completer.complete(false);
            },
          ),
        );
        
        await completer.future;
        if (mounted) {
          await _checkPermissions();
        }
      }
    }
  }

  AppSettingsType _getSettingsType(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return AppSettingsType.notification;
      case Permission.camera:
        return AppSettingsType.camera;
      case Permission.location:
        return AppSettingsType.location;
      default:
        return AppSettingsType.settings;
    }
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required Future<void> Function() onRequestPermission,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isGranted
          ? const Icon(Icons.check_circle, color: Colors.green)
          : TextButton(
              onPressed: onRequestPermission,
              child: const Text('Grant'),
            ),
    );
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
              'Device Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPermissionTile(
                title: 'Notifications',
                subtitle: 'Required to keep routines updated in the background',
                isGranted: _notificationPermission,
                onRequestPermission: () => _requestPermission(Permission.notification),
              ),
              const Divider(),
              _buildPermissionTile(
                title: 'Camera',
                subtitle: 'Required for scanning QR codes',
                isGranted: _cameraPermission,
                onRequestPermission: () => _requestPermission(Permission.camera),
              ),
              const Divider(),
              _buildPermissionTile(
                title: 'Location',
                subtitle: 'Required for creating and completing location conditions',
                isGranted: _locationPermission,
                onRequestPermission: () => _requestPermission(Permission.location),
              ),
              const Divider(),
              _buildPermissionTile(
                title: Platform.isIOS ? 'Screen Time Restrictions' : 'Accessibility',
                subtitle: 'Required to block apps and websites',
                isGranted: _blockPermission,
                onRequestPermission: _requestBlockPermissions,
              )
            ],
          ),
        ],
      ),
    );
  }
}
