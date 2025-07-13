import 'dart:async';
import 'dart:io' show Platform;

import 'package:Routine/channels/mobile_channel.dart';
import 'package:Routine/models/installed_app.dart';
import 'package:Routine/services/platform_service.dart';
import 'package:Routine/services/sync_service.dart';
import '../models/routine.dart';
import 'strict_mode_service.dart';

class MobileService extends PlatformService {
  static final MobileService _instance = MobileService._internal();
  
  factory MobileService() => _instance;
  
  MobileService._internal();
  
  final _mobileChannel = MobileChannel.instance;
  
  StreamSubscription? _routineSubscription;
  StreamSubscription? _strictModeSubscription;
  
  @override
  Future<void> init() async {    
    _routineSubscription = Routine
      .watchAll()
      .listen((routines) => _sendRoutines(routines, false));
    
    _strictModeSubscription = StrictModeService.instance.settingsStream
      .listen(_sendStrictModeSettings);
  }

  @override
  Future<void> refresh() async {
    SyncService().setupRealtimeSync();
    await stopWatching();
    await SyncService().queueSync();
    await init();
  }
  
  Future<void> stopWatching() async {
    await _routineSubscription?.cancel();
    _routineSubscription = null;
    await _strictModeSubscription?.cancel();
    _strictModeSubscription = null;
  }
  
  Future<void> _sendStrictModeSettings(Map<String, bool> settings) async {
    await _mobileChannel.updateStrictModeSettings(settings);
  }

  Future<void> updateRoutines({bool immediate = false}) async {
    final routines = await Routine.getAll();
    _sendRoutines(routines, immediate);
  }

  Future<List<InstalledApp>> getInstalledApps() async {
    return await _mobileChannel.getInstalledApps();
  }
  
  Future<void> _sendRoutines(List<Routine> routines, bool immediate) async {
    await _mobileChannel.updateRoutines(routines, immediate: immediate);
  }
  
  static MobileService get instance => _instance;
  
  Future<bool> getBlockPermissions({bool request = false}) async {
    if (Platform.isIOS) {
      final bool isAuthorized = await _mobileChannel.checkFamilyControlsAuthorization();

      if (isAuthorized) {
        return true;
      } else if (request) {
        return await _mobileChannel.requestFamilyControlsAuthorization();
      } else {
        return false;
      }
    } else {
      bool hasOverlayPermission = await _mobileChannel.checkOverlayPermission();
      bool hasAccessibilityPermission = await _mobileChannel.checkAccessibilityPermission();
      
      if (request) {
        if (!hasOverlayPermission) {
          hasOverlayPermission = await _mobileChannel.requestOverlayPermission();
        }
        
        if (!hasAccessibilityPermission) {
          hasAccessibilityPermission = await _mobileChannel.requestAccessibilityPermission();
        }
      }
      
      return hasOverlayPermission && hasAccessibilityPermission;
    }
  }
  
  Future<bool> checkOverlayPermission() async {
    return await _mobileChannel.checkOverlayPermission();
  }
  
  Future<bool> requestOverlayPermission() async {
    return await _mobileChannel.requestOverlayPermission();
  }
  
  Future<bool> checkAccessibilityPermission() async {
    return await _mobileChannel.checkAccessibilityPermission();
  }
  
  Future<bool> requestAccessibilityPermission() async {
    return await _mobileChannel.requestAccessibilityPermission();
  }
}
