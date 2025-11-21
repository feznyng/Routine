import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:routine_blocker/constants.dart';
import 'package:routine_blocker/models/installed_app.dart';
import 'package:routine_blocker/models/routine.dart';
import 'package:routine_blocker/setup.dart';
import 'package:routine_blocker/util.dart';

class MobileChannel {
  static final MobileChannel _instance = MobileChannel._();
  static MobileChannel get instance => _instance;

  final _channel = const MethodChannel(kAppName);
  MobileChannel._();
  Future<void> updateStrictModeSettings(Map<String, bool> settings) async {
    try {
      await _channel.invokeMethod('updateStrictModeSettings', settings);
    } catch (e, st) {
      Util.report('error sending strict mode settings', e, st);
    }
  }
  Future<List<InstalledApp>> getInstalledApps() async {
    List<InstalledApp> installedApps = [];

    logger.i("retrieving apps");

    final dynamic appList = await _channel.invokeMethod('retrieveAllApps');

    logger.i("finished retrieving apps = ${appList.length}");

    for (final app in appList) {
      installedApps.add(InstalledApp(name: app['name']!, filePath: app['filePath']!));
    }

    return installedApps;
  }
  Future<void> updateRoutines(List<Routine> routines, {bool immediate = false}) async {
    try {
      final List<Map<String, dynamic>> routineMaps = routines.where((routine) => routine.getGroup() != null).map((routine) {
        DateTime? conditionsLastMet;
        if (routine.conditions.isNotEmpty) {
          if (routine.conditions.any((condition) => condition.lastCompletedAt == null)) {
            conditionsLastMet = null;
          } else {
            conditionsLastMet = routine.conditions
                .map((condition) => condition.lastCompletedAt!)
                .reduce((earliest, date) => earliest.isBefore(date) ? earliest : date);
            if (conditionsLastMet.isAfter(routine.completableAt)) {
              conditionsLastMet = routine.startedAt.add(Duration(minutes: 1));
            }
          }
        }
        
        return {
          'id': routine.id,
          'name': routine.name,
          'days': routine.days,
          'startTime': routine.startTime,
          'endTime': routine.endTime,
          'allDay': routine.allDay,
          'pausedUntil': routine.pausedUntil?.toUtc().toIso8601String(),
          'snoozedUntil': routine.snoozedUntil?.toUtc().toIso8601String(),
          'apps': routine.apps,
          'sites': routine.sites,
          'categories': routine.categories,
          'allow': routine.allow,
          'conditionsMet': routine.areConditionsMet,
          'conditionsLastMet': conditionsLastMet?.toUtc().toIso8601String(),
          'strictMode': routine.strictMode,
        };
      }).toList();
            
      await _channel.invokeMethod(immediate ? 'immediateUpdateRoutines' : 'updateRoutines', {'routines': routineMaps});
    } catch (e, st) {
      Util.report('error updating routines', e, st);
    }
  }
  Future<bool> checkFamilyControlsAuthorization() async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod('checkFamilyControlsAuthorization');
  }

  Future<bool> requestFamilyControlsAuthorization() async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod('requestFamilyControlsAuthorization');
  }
  Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod('checkOverlayPermission');
  }
  
  Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod('requestOverlayPermission');
  }
  
  Future<bool> checkAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod('checkAccessibilityPermission');
  }
  
  Future<bool> requestAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod('requestAccessibilityPermission');
  }
}