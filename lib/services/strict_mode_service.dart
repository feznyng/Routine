import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
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
  
  DateTime? _extensionGracePeriodEnd;
  DateTime? _extensionCooldownEnd;
  static const int _extensionGracePeriodSeconds = 60;
  static const int _extensionCooldownMinutes = 10;
  
  Timer? _gracePeriodTimer;
  
  final StreamController<Map<String, bool>> _effectiveSettingsStreamController = StreamController<Map<String, bool>>.broadcast();
  final StreamController<void> _gracePeriodExpirationController = StreamController<void>.broadcast();
  
  StrictModeService._internal();
  
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
  
  void evaluateStrictMode(List<Routine> routines) {
    final activeRoutines = routines.where((r) => r.isActive && !r.isPaused).toList();
    
    final wasInStrictMode = _inStrictMode;
    _inStrictMode = activeRoutines.any((r) => r.strictMode);
    if (wasInStrictMode != _inStrictMode) {
      notifyListeners();
      
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
  
  bool get inStrictMode => _inStrictMode;
  
  bool get blockAppExit => _blockAppExit && !emergencyMode;
  bool get blockDisablingSystemStartup => _blockDisablingSystemStartup;
  bool get blockBrowsersWithoutExtension => _blockBrowsersWithoutExtension;
  bool get blockChangingTimeSettings => _blockChangingTimeSettings;
  bool get blockUninstallingApps => _blockUninstallingApps && !emergencyMode;
  bool get blockInstallingApps => _blockInstallingApps;
  
  bool get isInExtensionGracePeriod {
    if (_extensionGracePeriodEnd == null) return false;
    return DateTime.now().isBefore(_extensionGracePeriodEnd!);
  }
  
  bool get isInExtensionCooldown {
    if (_extensionCooldownEnd == null) return false;
    return DateTime.now().isBefore(_extensionCooldownEnd!);
  }
  
  int get remainingGracePeriodSeconds {
    if (!isInExtensionGracePeriod) return 0;
    return _extensionGracePeriodEnd!.difference(DateTime.now()).inSeconds;
  }
  
  int get remainingCooldownMinutes {
    if (!isInExtensionCooldown) return 0;
    return _extensionCooldownEnd!.difference(DateTime.now()).inMinutes + 1; // +1 to round up
  }
  
  bool get emergencyMode => _emergencyEvents.any((e) => e.isActive);
  List<EmergencyEvent> get emergencyEvents => _emergencyEvents;
  List<DateTime> get emergencyTimestamps => _emergencyEvents.map((e) => e.startedAt).toList();

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

  bool get effectiveBlockAppExit => _blockAppExit && _inStrictMode && !emergencyMode;
  bool get effectiveBlockDisablingSystemStartup => _blockDisablingSystemStartup && _inStrictMode && !emergencyMode;
  bool get effectiveBlockBrowsersWithoutExtension => _blockBrowsersWithoutExtension && _inStrictMode && !emergencyMode;
  bool get effectiveBlockChangingTimeSettings => _blockChangingTimeSettings && _inStrictMode && !emergencyMode;
  bool get effectiveBlockUninstallingApps => _blockUninstallingApps && _inStrictMode && !emergencyMode;
  bool get effectiveBlockInstallingApps => _blockInstallingApps && _inStrictMode && !emergencyMode;
  static const String _blockAppExitKey = 'block_app_exit';
  static const String _blockDisablingSystemStartupKey = 'block_disabling_system_startup';
  static const String _blockBrowsersWithoutExtensionKey = 'block_browsers_without_extension';
  static const String _blockChangingTimeSettingsKey = 'block_changing_time_settings';
  static const String _blockUninstallingAppsKey = 'block_uninstalling_apps';
  static const String _blockInstallingAppsKey = 'block_installing_apps';
  
  void startExtensionGracePeriod() {
    if (isInExtensionCooldown) {
      return;
    }
    
    _gracePeriodTimer?.cancel();
    
    _extensionGracePeriodEnd = DateTime.now().add(Duration(seconds: _extensionGracePeriodSeconds));
    
    _extensionCooldownEnd = DateTime.now().add(Duration(minutes: _extensionCooldownMinutes));
    _gracePeriodTimer = Timer(Duration(seconds: _extensionGracePeriodSeconds), () {
      _extensionGracePeriodEnd = null;
      
      notifyListeners();
      _notifyEffectiveSettingsChanged();
      _notifyGracePeriodExpired();
    });
    
    notifyListeners();
    
    // Grace period affects effective settings
    _notifyEffectiveSettingsChanged();
  }
  
  void endExtensionGracePeriod() {
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    
    _extensionGracePeriodEnd = null;
    notifyListeners();
    
    _notifyEffectiveSettingsChanged();
  }
  
  void cancelGracePeriodWithCooldown() {
    logger.i("canceling grace period with cooldown");
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    
    _extensionGracePeriodEnd = null;
    
    _extensionCooldownEnd ??= DateTime.now().add(Duration(minutes: _extensionCooldownMinutes));
    
    notifyListeners();
    _notifyEffectiveSettingsChanged();
    _notifyGracePeriodExpired();
  }
  
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
  
  Future<void> _updateBoolSetting(
    bool value,
    String key,
    bool Function() getter,
    void Function(bool) setter,
    {bool updateIOS = false}
  ) async {
    if (getter() == value) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    setter(value);
    notifyListeners();
    
    _notifyEffectiveSettingsChanged();
  }
  
  Future<void> setBlockAppExit(bool value) async {
    return _updateBoolSetting(
      value,
      _blockAppExitKey,
      () => _blockAppExit,
      (v) => _blockAppExit = v,
    );
  }
  
  Future<void> setBlockDisablingSystemStartup(bool value) async {
    return _updateBoolSetting(
      value,
      _blockDisablingSystemStartupKey,
      () => _blockDisablingSystemStartup,
      (v) => _blockDisablingSystemStartup = v,
    );
  }
  
  Future<void> setBlockBrowsersWithoutExtension(bool value) async {
    return _updateBoolSetting(
      value,
      _blockBrowsersWithoutExtensionKey,
      () => _blockBrowsersWithoutExtension,
      (v) => _blockBrowsersWithoutExtension = v,
    );
  }
  
  Future<void> setBlockChangingTimeSettings(bool value) async {
    return _updateBoolSetting(
      value,
      _blockChangingTimeSettingsKey,
      () => _blockChangingTimeSettings,
      (v) => _blockChangingTimeSettings = v,
      updateIOS: true,
    );
  }
  
  Future<void> setBlockUninstallingApps(bool value) async {
    return _updateBoolSetting(
      value,
      _blockUninstallingAppsKey,
      () => _blockUninstallingApps,
      (v) => _blockUninstallingApps = v,
      updateIOS: true,
    );
  }
  
  Future<void> setBlockInstallingApps(bool value) async {
    return _updateBoolSetting(
      value,
      _blockInstallingAppsKey,
      () => _blockInstallingApps,
      (v) => _blockInstallingApps = v,
      updateIOS: true,
    );
  }
  
  Future<void> setEmergencyMode(bool value) async {
    if (emergencyMode == value) return;
    
    if (value) {
      _emergencyEvents.add(EmergencyEvent(startedAt: DateTime.now()));
    } else {
      final activeEvent = _emergencyEvents.last;
      activeEvent.endedAt = DateTime.now();
    }
    await _storeEmergencyEvents();

    notifyListeners();
    _notifyEffectiveSettingsChanged();

    // Notify other devices of the change
    SyncService().addJob(SyncJob(remote: true));
  }

  Future<bool> _setSettingWithConfirmation(
    BuildContext context,
    bool value,
    String title,
    String message,
    Future<void> Function(bool) setter
  ) async {
    if (!value && _inStrictMode && !emergencyMode) {
      showStrictModeActiveDialog(context);
      return false;
    }
    if (value) {
      final bool? confirmed = await _showEnableConfirmationDialog(
        context, 
        title,
        message
      );
      if (confirmed != true) {
        return false;
      }
    }
    
    await setter(value);
    return true;
  }

  Future<bool> setBlockAppExitWithConfirmation(BuildContext context, bool value) async {
    return _setSettingWithConfirmation(
      context,
      value,
      'Block App Exit',
      'This will prevent the app from being closed when in strict mode. Are you sure you want to enable this setting?',
      setBlockAppExit
    );
  }
  
  Future<bool> setBlockDisablingSystemStartupWithConfirmation(BuildContext context, bool value) async {
    return _setSettingWithConfirmation(
      context,
      value,
      'Block Disabling System Startup',
      'This will prevent the app\'s startup setting from being disabled when in strict mode. Are you sure you want to enable this setting?',
      setBlockDisablingSystemStartup
    );
  }
  
  Future<bool> setBlockBrowsersWithoutExtensionWithConfirmation(BuildContext context, bool value) async {
    return _setSettingWithConfirmation(
      context,
      value,
      'Block Browsers Without Extension',
      'This will block browsers when the extension is not installed or not connected. Are you sure you want to enable this setting?',
      setBlockBrowsersWithoutExtension
    );
  }
  
  Future<bool> setBlockChangingTimeSettingsWithConfirmation(BuildContext context, bool value) async {
    return _setSettingWithConfirmation(
      context,
      value,
      'Block Changing Time Settings',
      'This will prevent changing the system time when in strict mode. Are you sure you want to enable this setting?',
      setBlockChangingTimeSettings
    );
  }
  
  Future<bool> setBlockUninstallingAppsWithConfirmation(BuildContext context, bool value) async {
    return _setSettingWithConfirmation(
      context,
      value,
      'Block Uninstalling Apps',
      'This will prevent uninstalling apps when in strict mode. Are you sure you want to enable this setting?',
      setBlockUninstallingApps
    );
  }
  
  Future<bool> setBlockInstallingAppsWithConfirmation(BuildContext context, bool value) async {
    return _setSettingWithConfirmation(
      context,
      value,
      'Block Installing Apps',
      'This will prevent installing new apps when in strict mode. Are you sure you want to enable this setting?',
      setBlockInstallingApps
    );
  }
  
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
  
  bool get isStrictModeEnabled {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _blockAppExit || _blockDisablingSystemStartup || _blockBrowsersWithoutExtension;
    } else if (Platform.isIOS) {
      return _blockChangingTimeSettings || _blockUninstallingApps || _blockInstallingApps;
    }
    return false;
  }
  
  bool get isEffectiveStrictModeEnabled {
    if (_inStrictMode) {
      return true;
    }
    return isStrictModeEnabled;
  }
  
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
  
  void _notifyEffectiveSettingsChanged() {
    final effectiveSettings = getCurrentEffectiveSettings();
    _effectiveSettingsStreamController.add(effectiveSettings);
    notifyListeners();
  }
  
  void _notifyGracePeriodExpired() {
    _gracePeriodExpirationController.add(null);
    notifyListeners();
  }
  
  Stream<Map<String, bool>> get effectiveSettingsStream => _effectiveSettingsStreamController.stream;
  Stream<void> get gracePeriodExpirationStream => _gracePeriodExpirationController.stream;
  
  @override
  void dispose() {
    _effectiveSettingsStreamController.close();
    _gracePeriodExpirationController.close();
    super.dispose();
  }
}
