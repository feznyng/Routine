import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'desktop_service.dart';
import 'package:flutter/material.dart';
import 'routine.dart';
import 'database.dart';

class StrictModeService with ChangeNotifier {
  static final StrictModeService _instance = StrictModeService._internal();
  
  factory StrictModeService() {
    return _instance;
  }
  
  // Private constructor
  StrictModeService._internal() {
    // We'll initialize the listener in the init method
  }
  
  static StrictModeService get instance => _instance;
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _inStrictMode = false;
  
  // Desktop strict mode settings
  bool _blockAppExit = false;
  bool _blockDisablingSystemStartup = false;
  
  // iOS strict mode settings
  bool _blockChangingTimeSettings = false;
  bool _blockUninstallingApps = false;
  bool _blockInstallingApps = false;
  
  // Evaluate if any active routines are in strict mode
  void _evaluateStrictMode(List<Routine> routines) {
    // Filter for active, not paused routines
    final activeRoutines = routines.where((r) => r.isActive && !r.isPaused).toList();
    
    // Check if any active routines are in strict mode
    final wasInStrictMode = _inStrictMode;
    _inStrictMode = activeRoutines.any((r) => r.strictMode);
    
    // Notify listeners if the strict mode status changed
    if (wasInStrictMode != _inStrictMode) {
      notifyListeners();
    }
  }
  
  // Getter for strict mode status
  bool get inStrictMode => _inStrictMode;
  
  // Basic getters for settings (without considering active routines)
  bool get blockAppExit => _blockAppExit;
  bool get blockDisablingSystemStartup => _blockDisablingSystemStartup;
  bool get blockChangingTimeSettings => _blockChangingTimeSettings;
  bool get blockUninstallingApps => _blockUninstallingApps;
  bool get blockInstallingApps => _blockInstallingApps;
  
  // Enhanced getters that consider if any active routine is in strict mode
  bool get effectiveBlockAppExit => _blockAppExit || _inStrictMode;
  bool get effectiveBlockDisablingSystemStartup => _blockDisablingSystemStartup || _inStrictMode;
  bool get effectiveBlockChangingTimeSettings => _blockChangingTimeSettings || _inStrictMode;
  bool get effectiveBlockUninstallingApps => _blockUninstallingApps || _inStrictMode;
  bool get effectiveBlockInstallingApps => _blockInstallingApps || _inStrictMode;
  
  // Shared preferences keys
  static const String _blockAppExitKey = 'block_app_exit';
  static const String _blockDisablingSystemStartupKey = 'block_disabling_system_startup';
  static const String _blockChangingTimeSettingsKey = 'block_changing_time_settings';
  static const String _blockUninstallingAppsKey = 'block_uninstalling_apps';
  static const String _blockInstallingAppsKey = 'block_installing_apps';
  
  // Initialize the service by loading saved preferences
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    
    // Load desktop settings
    _blockAppExit = prefs.getBool(_blockAppExitKey) ?? false;
    _blockDisablingSystemStartup = prefs.getBool(_blockDisablingSystemStartupKey) ?? false;
    
    // Load iOS settings
    _blockChangingTimeSettings = prefs.getBool(_blockChangingTimeSettingsKey) ?? false;
    _blockUninstallingApps = prefs.getBool(_blockUninstallingAppsKey) ?? false;
    _blockInstallingApps = prefs.getBool(_blockInstallingAppsKey) ?? false;
    
    _initialized = true;
    
    // Listen for routine changes to update strict mode status
    Routine.watchAll().listen(_evaluateStrictMode);
    
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
  
  // Set desktop settings with confirmation when needed
  Future<bool> setBlockAppExitWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode, block the change
    if (!value && _inStrictMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block App Exit',
        'This will prevent the app from being closed. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockAppExit(value);
    return true;
  }
  
  Future<bool> setBlockDisablingSystemStartupWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode, block the change
    if (!value && _inStrictMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Disabling System Startup',
        'This will prevent the app\'s startup setting from being disabled. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockDisablingSystemStartup(value);
    return true;
  }
  
  // Set iOS settings with confirmation when needed
  Future<bool> setBlockChangingTimeSettingsWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode, block the change
    if (!value && _inStrictMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Changing Time Settings',
        'This will prevent changing the system time. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockChangingTimeSettings(value);
    return true;
  }
  
  Future<bool> setBlockUninstallingAppsWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode, block the change
    if (!value && _inStrictMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Uninstalling Apps',
        'This will prevent uninstalling apps. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockUninstallingApps(value);
    return true;
  }
  
  Future<bool> setBlockInstallingAppsWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode, block the change
    if (!value && _inStrictMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Installing Apps',
        'This will prevent installing new apps. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockInstallingApps(value);
    return true;
  }
  
  // Helper method to show a dialog when strict mode is active (public method)
  void showStrictModeActiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Strict Mode Active'),
          content: const Text(
            'You cannot disable this setting while strict mode is active. Wait until all routines with strict mode are inactive, or disable strict mode for those routines first.'
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  // Helper method to show a dialog when strict mode is active
  void _showStrictModeActiveDialog(BuildContext context) {
    showStrictModeActiveDialog(context);
  }
  
  // Helper method to show a confirmation dialog when enabling a setting
  Future<bool?> _showEnableConfirmationDialog(BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enable $title'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }
  
  // Check if any strict mode setting is enabled (based on settings only)
  bool get isStrictModeEnabled {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _blockAppExit || _blockDisablingSystemStartup;
    } else if (Platform.isIOS) {
      return _blockChangingTimeSettings || _blockUninstallingApps || _blockInstallingApps;
    }
    return false;
  }
  
  // Check if any strict mode setting is effectively enabled (considering active routines)
  bool get isEffectiveStrictModeEnabled {
    if (_inStrictMode) {
      return true;
    }
    return isStrictModeEnabled;
  }
}
