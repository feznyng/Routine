import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:routine_blocker/services/mobile_service.dart';

import 'android_permissions_onboarding_dialog.dart';

Future<void> runBlockPermissionsSetupFlow(BuildContext context) async {
  if (Platform.isIOS) {
    final granted = await MobileService.instance.getBlockPermissions(request: true);
    if (!granted) {
      AppSettings.openAppSettings(type: AppSettingsType.settings);
    }
  } else if (Platform.isAndroid) {
    final mobileService = MobileService.instance;
    final hasOverlay = await mobileService.checkOverlayPermission();
    final hasAccessibility = await mobileService.checkAccessibilityPermission();

    if (!hasOverlay || !hasAccessibility) {
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
    }
  }
}
