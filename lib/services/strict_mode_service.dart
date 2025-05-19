import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/routine.dart';
import '../models/emergency_event.dart';
import '../services/sync_service.dart';
import 'package:Routine/setup.dart';

class StrictModeService with ChangeNotifier {
  static final StrictModeService _instance = StrictModeService._internal();
  
  factory StrictModeService() {
    return _instance;
  }
  
  // Grace period for extension reinstallation
  DateTime? _extensionGracePeriodEnd;
  DateTime? _extensionCooldownEnd;
  static const int _extensionGracePeriodSeconds = 60; // Changed to 60 seconds as per requirements
  static const int _extensionCooldownMinutes = 10;
  
  // Timer for grace period expiration
  Timer? _gracePeriodTimer;
  
  // List of listeners specifically for grace period expiration
  final List<Function()> _gracePeriodExpirationListeners = [];
  
  // Stream controller for effective settings changes
  final StreamController<Map<String, bool>> _effectiveSettingsStreamController = StreamController<Map<String, bool>>.broadcast();
  
  // Private constructor
  StrictModeService._internal() {
    // We'll initialize the listener in the init method
  }
  
  static StrictModeService get instance => _instance;
  
  bool _initialized = false;
  bool _inStrictMode = false;

  static const String _emergencyEventsKey = 'emergencyEvents';
  static const int _maxEmergenciesPerWeek = 2;

  List<EmergencyEvent> _emergencyEvents = [];

  // Desktop strict mode settings
  bool _blockAppExit = false;
  bool _blockDisablingSystemStartup = false;
  bool _blockBrowsersWithoutExtension = false;
  
  // iOS strict mode settings
  bool _blockChangingTimeSettings = false;
  bool _blockUninstallingApps = false;
  bool _blockInstallingApps = false;
  
  // Evaluate if any active routines are in strict mode
  void evaluateStrictMode(List<Routine> routines) {
    // Filter for active, not paused routines
    final activeRoutines = routines.where((r) => r.isActive && !r.isPaused).toList();
    
    // Check if any active routines are in strict mode
    final wasInStrictMode = _inStrictMode;
    _inStrictMode = activeRoutines.any((r) => r.strictMode);
    
    // Notify listeners if the strict mode status changed
    if (wasInStrictMode != _inStrictMode) {
      notifyListeners();
      
      // Update iOS if on iOS platform
      if (Platform.isIOS) {
        _updateIOSStrictModeSettings();
      }
      
      // Notify effective settings listeners since effective settings depend on _inStrictMode
      _notifyEffectiveSettingsChanged();
    }
  }

  Future<bool> isGroupLockedDown(String groupId) async {
    final routines = await Routine.getAll();

    bool lockedDown = false;
    for (final routine in routines) {
      if (routine.getGroup()?.id == groupId && routine.isActive && routine.strictMode) {
        lockedDown = true;
        break;
      }
    }

    return lockedDown;
  }
  
  // Getter for strict mode status
  bool get inStrictMode => _inStrictMode;
  
  // Basic getters for settings (without considering active routines)
  bool get blockAppExit => _blockAppExit && !emergencyMode;
  bool get blockDisablingSystemStartup => _blockDisablingSystemStartup;
  bool get blockBrowsersWithoutExtension => _blockBrowsersWithoutExtension;
  bool get blockChangingTimeSettings => _blockChangingTimeSettings;
  bool get blockUninstallingApps => _blockUninstallingApps && !emergencyMode;
  bool get blockInstallingApps => _blockInstallingApps;
  
  // Grace period getters
  bool get isInExtensionGracePeriod {
    if (_extensionGracePeriodEnd == null) return false;
    return DateTime.now().isBefore(_extensionGracePeriodEnd!);
  }
  
  bool get isInExtensionCooldown {
    if (_extensionCooldownEnd == null) return false;
    return DateTime.now().isBefore(_extensionCooldownEnd!);
  }
  
  // Remaining time in grace period (in seconds)
  int get remainingGracePeriodSeconds {
    if (!isInExtensionGracePeriod) return 0;
    return _extensionGracePeriodEnd!.difference(DateTime.now()).inSeconds;
  }
  
  // Remaining time in cooldown (in minutes)
  int get remainingCooldownMinutes {
    if (!isInExtensionCooldown) return 0;
    return _extensionCooldownEnd!.difference(DateTime.now()).inMinutes + 1; // +1 to round up
  }
  
  // Emergency mode getters
  bool get emergencyMode => _emergencyEvents.any((e) => e.isActive);
  List<EmergencyEvent> get emergencyEvents => _emergencyEvents;
  List<DateTime> get emergencyTimestamps => _emergencyEvents.map((e) => e.startedAt).toList();

  // Update emergency events from sync
  Future<void> updateEmergencyEvents(List<EmergencyEvent> events) async {
    _emergencyEvents = events;
    await _storeEmergencyEvents();
  }

  Future<void> _storeEmergencyEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emergencyEventsKey, 
      jsonEncode(_emergencyEvents.map((e) => e.toJson()).toList()));
  }

  int get remainingEmergencies {
    // Remove events older than a week
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    _emergencyEvents.removeWhere((e) => e.startedAt.isBefore(oneWeekAgo));
    return _maxEmergenciesPerWeek - _emergencyEvents.length;
  }

  bool get canStartEmergency {
    // Remove events older than a week
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    _emergencyEvents.removeWhere((e) => e.startedAt.isBefore(oneWeekAgo));
    return _emergencyEvents.length < _maxEmergenciesPerWeek;
  }

  // Enhanced getters that consider if any active routine is in strict mode AND emergency mode is off
  bool get effectiveBlockAppExit => _blockAppExit && _inStrictMode && !emergencyMode;
  bool get effectiveBlockDisablingSystemStartup => _blockDisablingSystemStartup && _inStrictMode && !emergencyMode;
  bool get effectiveBlockBrowsersWithoutExtension => _blockBrowsersWithoutExtension && _inStrictMode && !emergencyMode;
  bool get effectiveBlockChangingTimeSettings => _blockChangingTimeSettings && _inStrictMode && !emergencyMode;
  bool get effectiveBlockUninstallingApps => _blockUninstallingApps && _inStrictMode && !emergencyMode;
  bool get effectiveBlockInstallingApps => _blockInstallingApps && _inStrictMode && !emergencyMode;
  
  // Shared preferences keys
  static const String _blockAppExitKey = 'block_app_exit';
  static const String _blockDisablingSystemStartupKey = 'block_disabling_system_startup';
  static const String _blockBrowsersWithoutExtensionKey = 'block_browsers_without_extension';
  static const String _blockChangingTimeSettingsKey = 'block_changing_time_settings';
  static const String _blockUninstallingAppsKey = 'block_uninstalling_apps';
  static const String _blockInstallingAppsKey = 'block_installing_apps';
  
  // Start a grace period for extension reinstallation
  void startExtensionGracePeriod() {
    // Check if in cooldown
    if (isInExtensionCooldown) {
      return;
    }
    
    // Cancel any existing timer
    _gracePeriodTimer?.cancel();
    
    // Set grace period end time
    _extensionGracePeriodEnd = DateTime.now().add(Duration(seconds: _extensionGracePeriodSeconds));
    
    // Set cooldown end time
    _extensionCooldownEnd = DateTime.now().add(Duration(minutes: _extensionCooldownMinutes));
    
    // Set up a timer to handle grace period expiration
    _gracePeriodTimer = Timer(Duration(seconds: _extensionGracePeriodSeconds), () {
      // Grace period has expired
      _extensionGracePeriodEnd = null;
      
      // Notify general listeners
      notifyListeners();
      
      // Notify effective settings listeners
      _notifyEffectiveSettingsChanged();
      
      // Notify grace period expiration listeners
      _notifyGracePeriodExpired();
    });
    
    notifyListeners();
    
    // Grace period affects effective settings
    _notifyEffectiveSettingsChanged();
  }
  
  // End the grace period early
  void endExtensionGracePeriod() {
    // Cancel the grace period timer
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    
    _extensionGracePeriodEnd = null;
    notifyListeners();
    
    // Grace period affects effective settings
    _notifyEffectiveSettingsChanged();
  }
  
  // Cancel the grace period and go directly to cooldown
  void cancelGracePeriodWithCooldown() {
    logger.i("canceling grace period with cooldown");
    // Cancel the grace period timer
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    
    // End grace period
    _extensionGracePeriodEnd = null;
    
    // Ensure cooldown is set
    _extensionCooldownEnd ??= DateTime.now().add(Duration(minutes: _extensionCooldownMinutes));
    
    notifyListeners();
    
    // Notify listeners about the changes
    _notifyEffectiveSettingsChanged();
    _notifyGracePeriodExpired();
  }
  
  // Initialize the service by loading saved preferences
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load desktop settings
    _blockAppExit = prefs.getBool(_blockAppExitKey) ?? false;
    _blockDisablingSystemStartup = prefs.getBool(_blockDisablingSystemStartupKey) ?? false;
    _blockBrowsersWithoutExtension = prefs.getBool(_blockBrowsersWithoutExtensionKey) ?? false;
    
    // Load iOS settings
    _blockChangingTimeSettings = prefs.getBool(_blockChangingTimeSettingsKey) ?? false;
    _blockUninstallingApps = prefs.getBool(_blockUninstallingAppsKey) ?? false;
    _blockInstallingApps = prefs.getBool(_blockInstallingAppsKey) ?? false;

    // Load emergency events
    final eventsJson = prefs.getString(_emergencyEventsKey);
    if (eventsJson != null) {
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      _emergencyEvents = eventsList
          .map((e) => EmergencyEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      _emergencyEvents = [];
    }
    
    // Store events to ensure they're properly persisted
    await _storeEmergencyEvents();
    
    _initialized = true;
    
    notifyListeners();
    
    // Initial notification of effective settings
    _notifyEffectiveSettingsChanged();
  }
  
  // Set desktop settings
  Future<void> setBlockAppExit(bool value) async {
    if (_blockAppExit == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockAppExitKey, value);
    _blockAppExit = value;
    notifyListeners();
    
    // Notify effective settings listeners
    _notifyEffectiveSettingsChanged();
  }
  
  Future<void> setBlockDisablingSystemStartup(bool value) async {
    if (_blockDisablingSystemStartup == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockDisablingSystemStartupKey, value);
    _blockDisablingSystemStartup = value;
    notifyListeners();
    
    // Notify effective settings listeners
    _notifyEffectiveSettingsChanged();
  }
  
  Future<void> setBlockBrowsersWithoutExtension(bool value) async {
    if (_blockBrowsersWithoutExtension == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockBrowsersWithoutExtensionKey, value);
    _blockBrowsersWithoutExtension = value;
    notifyListeners();
    
    // Notify effective settings listeners
    _notifyEffectiveSettingsChanged();
  }
  
  // Set iOS settings
  Future<void> setBlockChangingTimeSettings(bool value) async {
    if (_blockChangingTimeSettings == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockChangingTimeSettingsKey, value);
    _blockChangingTimeSettings = value;
    notifyListeners();
    
    // Update iOS if on iOS platform
    if (Platform.isIOS) {
      _updateIOSStrictModeSettings();
    }
    
    // Notify effective settings listeners
    _notifyEffectiveSettingsChanged();
  }
  
  Future<void> setBlockUninstallingApps(bool value) async {
    if (_blockUninstallingApps == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockUninstallingAppsKey, value);
    _blockUninstallingApps = value;
    notifyListeners();
    
    // Update iOS if on iOS platform
    if (Platform.isIOS) {
      _updateIOSStrictModeSettings();
    }
    
    // Notify effective settings listeners
    _notifyEffectiveSettingsChanged();
  }
  
  Future<void> setBlockInstallingApps(bool value) async {
    if (_blockInstallingApps == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockInstallingAppsKey, value);
    _blockInstallingApps = value;
    notifyListeners();
    
    // Update iOS if on iOS platform
    if (Platform.isIOS) {
      _updateIOSStrictModeSettings();
    }
    
    // Notify effective settings listeners
    _notifyEffectiveSettingsChanged();
  }
  
  // Helper method to update iOS strict mode settings
  void _updateIOSStrictModeSettings() {
    if (Platform.isIOS) {
      // Use method channel directly to avoid circular dependency
      const MethodChannel _channel = MethodChannel('com.routine.ios_channel');
      try {
        final Map<String, dynamic> settings = {
          'blockChangingTimeSettings': blockChangingTimeSettings,
          'blockUninstallingApps': blockUninstallingApps,
          'blockInstallingApps': blockInstallingApps,
          'inStrictMode': inStrictMode,
        };
        
        // Send settings to iOS via platform channel
        _channel.invokeMethod('updateStrictModeSettings', settings);
        logger.i('Updated iOS strict mode settings via direct channel');
        
        // Also store in shared preferences with the required key
        _storeStrictModeDataInSharedPreferences(settings);
      } catch (e) {
        logger.e('Error updating iOS strict mode settings: $e');
      }
    }
  }
  
  // Method to toggle emergency mode
  Future<void> setEmergencyMode(bool value) async {
    if (emergencyMode == value) return;
    
    // When enabling emergency mode, create new event
    if (value) {
      _emergencyEvents.add(EmergencyEvent(startedAt: DateTime.now()));
    } else {
      // When disabling, find the active event and set its end time
      final activeEvent = _emergencyEvents.last;
      activeEvent.endedAt = DateTime.now();
    }
    await _storeEmergencyEvents();

    notifyListeners();
    _notifyEffectiveSettingsChanged();

    // Notify other devices of the change
    SyncService().addJob(SyncJob(remote: true));
  }

  // Helper method to store strict mode data in shared preferences
  Future<void> _storeStrictModeDataInSharedPreferences(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings);
      await prefs.setString('strictModeData', jsonString);
      logger.i('Stored strict mode data in shared preferences');
    } catch (e) {
      logger.e('Error storing strict mode data in shared preferences: $e');
    }
  }
  
  // Set desktop settings with confirmation when needed
  Future<bool> setBlockAppExitWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode and not in emergency mode, block the change
    if (!value && _inStrictMode && !emergencyMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block App Exit',
        'This will prevent the app from being closed when in strict mode. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockAppExit(value);
    return true;
  }
  
  Future<bool> setBlockDisablingSystemStartupWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode and not in emergency mode, block the change
    if (!value && _inStrictMode && !emergencyMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Disabling System Startup',
        'This will prevent the app\'s startup setting from being disabled when in strict mode. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockDisablingSystemStartup(value);
    return true;
  }
  
  Future<bool> setBlockBrowsersWithoutExtensionWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode and not in emergency mode, block the change
    if (!value && _inStrictMode && !emergencyMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Browsers Without Extension',
        'This will block browsers when the extension is not installed or not connected. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockBrowsersWithoutExtension(value);
    return true;
  }
  
  // Set iOS settings with confirmation when needed
  Future<bool> setBlockChangingTimeSettingsWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode and not in emergency mode, block the change
    if (!value && _inStrictMode && !emergencyMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Changing Time Settings',
        'This will prevent changing the system time when in strict mode. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockChangingTimeSettings(value);
    return true;
  }
  
  Future<bool> setBlockUninstallingAppsWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode and not in emergency mode, block the change
    if (!value && _inStrictMode && !emergencyMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Uninstalling Apps',
        'This will prevent uninstalling apps when in strict mode. Are you sure you want to enable this setting?'
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setBlockUninstallingApps(value);
    return true;
  }
  
  Future<bool> setBlockInstallingAppsWithConfirmation(BuildContext context, bool value) async {
    // If trying to disable while in strict mode and not in emergency mode, block the change
    if (!value && _inStrictMode && !emergencyMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    
    // If enabling, show confirmation dialog
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        'Block Installing Apps',
        'This will prevent installing new apps when in strict mode. Are you sure you want to enable this setting?'
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
      return _blockAppExit || _blockDisablingSystemStartup || _blockBrowsersWithoutExtension;
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
  
  // Get the current effective settings as a map
  Map<String, bool> getCurrentEffectiveSettings() {
    return {
      'blockAppExit': effectiveBlockAppExit,
      'blockDisablingSystemStartup': effectiveBlockDisablingSystemStartup,
      'blockBrowsersWithoutExtension': effectiveBlockBrowsersWithoutExtension,
      'blockChangingTimeSettings': effectiveBlockChangingTimeSettings,
      'blockUninstallingApps': effectiveBlockUninstallingApps,
      'blockInstallingApps': effectiveBlockInstallingApps,
      'inStrictMode': inStrictMode,
      'isInExtensionGracePeriod': isInExtensionGracePeriod,
      'isInExtensionCooldown': isInExtensionCooldown,
    };
  }
  
  // Notify all effective settings listeners of changes
  void _notifyEffectiveSettingsChanged() {
    final effectiveSettings = getCurrentEffectiveSettings();
    
    // Notify through the stream
    _effectiveSettingsStreamController.add(effectiveSettings);
    
    // Notify ChangeNotifier listeners
    notifyListeners();
  }
  
  // Notify all grace period expiration listeners
  void _notifyGracePeriodExpired() {
    for (final listener in _gracePeriodExpirationListeners) {
      listener();
    }
  }
  
  // The following methods are maintained for backward compatibility
  // but now use the ChangeNotifier mechanism internally
  
  // Add a listener for effective settings changes
  void addEffectiveSettingsListener(Function(Map<String, bool>) listener) {
    // This is now handled by ChangeNotifier
    // Just call the listener with current settings for immediate update
    listener(getCurrentEffectiveSettings());
  }
  
  // Remove a listener for effective settings changes
  void removeEffectiveSettingsListener(Function(Map<String, bool>) listener) {
    // This is now handled by ChangeNotifier
    // No need to do anything here
  }
  
  // Add a listener for grace period expiration
  void addGracePeriodExpirationListener(Function() listener) {
    if (!_gracePeriodExpirationListeners.contains(listener)) {
      _gracePeriodExpirationListeners.add(listener);
    }
  }
  
  // Remove a listener for grace period expiration
  void removeGracePeriodExpirationListener(Function() listener) {
    _gracePeriodExpirationListeners.remove(listener);
  }
  
  // Get a stream of effective settings changes
  Stream<Map<String, bool>> get effectiveSettingsStream => _effectiveSettingsStreamController.stream;
  
  // Clean up resources when the service is disposed
  @override
  void dispose() {
    _gracePeriodExpirationListeners.clear();
    _effectiveSettingsStreamController.close();
    super.dispose();
  }
}
