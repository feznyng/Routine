import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class StrictModeService with ChangeNotifier {
  static final StrictModeService _instance = StrictModeService._internal();
  
  factory StrictModeService() {
    return _instance;
  }
  
  StrictModeService._internal();
  
  static StrictModeService get instance => _instance;
  
  // Desktop strict mode settings
  bool _blockAppExit = false;
  bool _blockDisablingSystemStartup = false;
  
  // iOS strict mode settings
  bool _blockChangingTimeSettings = false;
  bool _blockUninstallingApps = false;
  bool _blockInstallingApps = false;
  
  // Getters for desktop settings
  bool get blockAppExit => _blockAppExit;
  bool get blockDisablingSystemStartup => _blockDisablingSystemStartup;
  
  // Getters for iOS settings
  bool get blockChangingTimeSettings => _blockChangingTimeSettings;
  bool get blockUninstallingApps => _blockUninstallingApps;
  bool get blockInstallingApps => _blockInstallingApps;
  
  // Shared preferences keys
  static const String _blockAppExitKey = 'block_app_exit';
  static const String _blockDisablingSystemStartupKey = 'block_disabling_system_startup';
  static const String _blockChangingTimeSettingsKey = 'block_changing_time_settings';
  static const String _blockUninstallingAppsKey = 'block_uninstalling_apps';
  static const String _blockInstallingAppsKey = 'block_installing_apps';
  
  // Initialize the service by loading saved preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load desktop settings
    _blockAppExit = prefs.getBool(_blockAppExitKey) ?? false;
    _blockDisablingSystemStartup = prefs.getBool(_blockDisablingSystemStartupKey) ?? false;
    
    // Load iOS settings
    _blockChangingTimeSettings = prefs.getBool(_blockChangingTimeSettingsKey) ?? false;
    _blockUninstallingApps = prefs.getBool(_blockUninstallingAppsKey) ?? false;
    _blockInstallingApps = prefs.getBool(_blockInstallingAppsKey) ?? false;
    
    notifyListeners();
  }
  
  // Set desktop settings
  Future<void> setBlockAppExit(bool value) async {
    if (_blockAppExit == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockAppExitKey, value);
    _blockAppExit = value;
    notifyListeners();
  }
  
  Future<void> setBlockDisablingSystemStartup(bool value) async {
    if (_blockDisablingSystemStartup == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockDisablingSystemStartupKey, value);
    _blockDisablingSystemStartup = value;
    notifyListeners();
  }
  
  // Set iOS settings
  Future<void> setBlockChangingTimeSettings(bool value) async {
    if (_blockChangingTimeSettings == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockChangingTimeSettingsKey, value);
    _blockChangingTimeSettings = value;
    notifyListeners();
  }
  
  Future<void> setBlockUninstallingApps(bool value) async {
    if (_blockUninstallingApps == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockUninstallingAppsKey, value);
    _blockUninstallingApps = value;
    notifyListeners();
  }
  
  Future<void> setBlockInstallingApps(bool value) async {
    if (_blockInstallingApps == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockInstallingAppsKey, value);
    _blockInstallingApps = value;
    notifyListeners();
  }
  
  // Check if any strict mode setting is enabled
  bool get isStrictModeEnabled {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _blockAppExit || _blockDisablingSystemStartup;
    } else if (Platform.isIOS) {
      return _blockChangingTimeSettings || _blockUninstallingApps || _blockInstallingApps;
    }
    return false;
  }
}
