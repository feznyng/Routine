import 'dart:async';
import 'package:routine_blocker/setup.dart';
import 'package:flutter/services.dart';
import 'package:routine_blocker/constants.dart';
import 'package:routine_blocker/models/installed_app.dart';
import 'package:routine_blocker/util.dart';


class BrowserControlMessage {
  String bundleId;
  bool controllable;

  BrowserControlMessage({required this.bundleId, required this.controllable});
}

class DesktopChannel {
  static final DesktopChannel _instance = DesktopChannel._();
  static DesktopChannel get instance => _instance;

  final _platform = const MethodChannel(kAppName);
  final _browserControllabilityController = StreamController<BrowserControlMessage>.broadcast();
  Future<void> Function()? _systemWakeHandler;
  DesktopChannel._();
  Future<void> signalEngineReady() async {
    try {
      await _platform.invokeMethod('engineReady');
    } catch (e, st) {
      Util.report('Failed to signal engine start', e, st);
    }
  }
  Future<void> updateBlockingList({
    required List<String> apps,
    required List<String> sites,
    required List<String> categories,
    required bool allowList,
  }) async {
    await _platform.invokeMethod('updateAppList', {
      'apps': apps,
      'sites': sites, // we also send sites for macos script-based blocking
      'categories': categories,
      'allowList': allowList,
    });
  }
  Future<void> setStartOnLogin(bool enabled) async {
    try {
      await _platform.invokeMethod('setStartOnLogin', enabled);
    } catch (e, st) {
      Util.report('error setting start on login to $enabled', e, st);
    }
  }
  Future<bool> getStartOnLogin() async {
    try {
      final bool enabled = await _platform.invokeMethod('getStartOnLogin');
      return enabled;
    } catch (e, st) {
      Util.report('failed retrieving startup on login status', e, st);
      return false;
    }
  }
  Future<List<InstalledApp>> getRunningApplications() async {
    List<InstalledApp> installedApps = [];
    try {
      final List<dynamic> runningApps = await _platform.invokeMethod('getRunningApplications');
      for (final app in runningApps) {
        final String name = app['name'];
        final String path = app['path'];
        final String? displayName = app['displayName'];
        if (name.isEmpty || 
            path.toLowerCase().contains('\\windows\\system32\\') ||
            path.toLowerCase().contains('\\windows\\syswow64\\')) {
          continue;
        }
        if (!installedApps.any((existingApp) => existingApp.filePath == path)) {
          installedApps.add(InstalledApp(
            name: displayName ?? name,
            filePath: path
          ));
        }
      }
    } catch (e, st) {
      Util.report('error retrieving installed applications', e, st);
    }
    return installedApps;
  }
  void registerSystemWakeHandler(Future<void> Function() handler) {
    _systemWakeHandler = handler;
    _platform.setMethodCallHandler(_handleMethodCall);
  }
  Future<bool> hasAutomationPermission(String bundleId) async {
    try {
      final result = await _platform.invokeMethod('hasAutomationPermission', bundleId);
      return result ?? false;
    } catch (e) {
      logger.e('Error checking automation permission: $e');
      return false;
    }
  }

  Future<bool> requestAutomationPermission(String bundleId, {bool openPrefsOnReject = false}) async {
    try {
      final result = await _platform.invokeMethod('requestAutomationPermission', {
        'bundleId': bundleId,
        'openPrefsOnReject': openPrefsOnReject,
      });
      return result ?? false;
    } catch (e) {
      logger.e('Error requesting automation permission: $e');
      return false;
    }
  }
  Stream<BrowserControlMessage> get browserControllabilityStream => _browserControllabilityController.stream;
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'systemWake':
        if (_systemWakeHandler != null) {
          logger.i('=== SYSTEM WAKE EVENT ===');
          await _systemWakeHandler!();
          logger.i('=== SYSTEM WAKE EVENT PROCESSING COMPLETE ===');
        }
        break;
      case 'browserControllabilityChanged':
        logger.i("browserControllabilityChanged - args = ${call.arguments}");
        final args = call.arguments;
        _browserControllabilityController.add(BrowserControlMessage(bundleId: args['bundleId'], controllable: args['isControllable']));
        break;
      default:
        logger.e('Unknown method call: ${call.method}');
        throw PlatformException(
          code: 'Unimplemented',
          message: "Method ${call.method} not implemented",
        );
    }
  }
  void dispose() {
    _browserControllabilityController.close();
  }
}