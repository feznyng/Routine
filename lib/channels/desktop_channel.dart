import 'package:Routine/setup.dart';
import 'package:flutter/services.dart';
import 'package:Routine/constants.dart';
import 'package:Routine/models/installed_app.dart';
import 'package:Routine/util.dart';

class DesktopChannel {
  // Singleton instance
  static final DesktopChannel _instance = DesktopChannel._();
  static DesktopChannel get instance => _instance;

  final _platform = const MethodChannel(kAppName);

  // Private constructor
  DesktopChannel._();

  // Signal that the engine is ready
  Future<void> signalEngineReady() async {
    try {
      await _platform.invokeMethod('engineReady');
    } catch (e, st) {
      Util.report('Failed to signal engine start', e, st);
    }
  }

  // Update app and site blocking list
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

  // Set start on login for macOS
  Future<void> setStartOnLogin(bool enabled) async {
    try {
      await _platform.invokeMethod('setStartOnLogin', enabled);
    } catch (e, st) {
      Util.report('error setting start on login to $enabled', e, st);
    }
  }

  // Get start on login status for macOS
  Future<bool> getStartOnLogin() async {
    try {
      final bool enabled = await _platform.invokeMethod('getStartOnLogin');
      return enabled;
    } catch (e, st) {
      Util.report('failed retrieving startup on login status', e, st);
      return false;
    }
  }

  // Get running applications for Windows
  Future<List<InstalledApp>> getRunningApplications() async {
    List<InstalledApp> installedApps = [];
    try {
      final List<dynamic> runningApps = await _platform.invokeMethod('getRunningApplications');
      
      // Convert the result to InstalledApplication objects
      for (final app in runningApps) {
        final String name = app['name'];
        final String path = app['path'];
        final String? displayName = app['displayName'];
        
        // Skip system processes and empty names
        if (name.isEmpty || 
            path.toLowerCase().contains('\\windows\\system32\\') ||
            path.toLowerCase().contains('\\windows\\syswow64\\')) {
          continue;
        }
        
        // Add to the list if not already present
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

  // Register system wake event handler
  void registerSystemWakeHandler(Future<void> Function() handler) {
    _platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'systemWake':
          logger.i('=== SYSTEM WAKE EVENT ===');
          await handler();
          logger.i('=== SYSTEM WAKE EVENT PROCESSING COMPLETE ===');
          return null;
        default:
          logger.e('Unknown method call: ${call.method}');
          throw PlatformException(
            code: 'Unimplemented',
            message: "Method ${call.method} not implemented",
          );
      }
    });
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
}