import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'routine.dart';
import 'package:cron/cron.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InstalledApplication {
  final String name;
  final String filePath;

  InstalledApplication({
    required this.name,
    required this.filePath,
  });

  @override
  String toString() => 'InstalledApplication(name: $name, filePath: $filePath)';
}

class DesktopService {
  // Singleton instance
  static final DesktopService _instance = DesktopService();

  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];

  DesktopService();

  static DesktopService get instance => _instance;

  final platform = const MethodChannel('com.routine.applist');
  Socket? _socket;
  bool _connected = false;
  List<int> _messageBuffer = [];
  int? _expectedLength;

  // Cache fields for blocked items
  List<String> _cachedSites = [];
  List<String> _cachedApps = [];
  bool _isAllowList = false;

  // Set of browser names in lowercase for O(1) lookup
  final Set<String> _browserNames = {
    'google chrome',
    'firefox',
    'safari',
    'microsoft edge',
    'opera',
    'brave browser',
  };

  Future<void> init() async {
    await _connectToNMH();

    // Set up platform channel method handler
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'activeApplication':
          final appName = call.arguments as String;

          // Check if the active application is a browser using O(1) lookup
          final lowerAppName = appName.toLowerCase();
          if (_browserNames.any((browser) => lowerAppName.contains(browser))) {
            updateBlockedSites();
          }
          break;
      }
    });

    // Signal to native code that Flutter is ready to receive messages
    try {
      await platform.invokeMethod('engineReady');
    } catch (e) {
      debugPrint('Failed to signal engine ready: $e');
    }

    Routine.watchAll().listen((routines) {
      onRoutinesUpdated(routines);
    });
  }

  void onRoutinesUpdated(List<Routine> routines) async {
    Set<Schedule> evaluationTimes = {};
    for (final Routine routine in routines) {
      evaluationTimes.add(Schedule(hours: routine.startHour, minutes: routine.startMinute));
      evaluationTimes.add(Schedule(hours: routine.endHour, minutes: routine.endMinute));

      if (routine.pausedUntil != null && routine.pausedUntil!.isAfter(DateTime.now())) {
        evaluationTimes.add(Schedule(hours: routine.pausedUntil!.hour, minutes: routine.pausedUntil!.minute));
      }
    }

    for (final ScheduledTask task in _scheduledTasks) {
      task.cancel();
    }
    _scheduledTasks.clear();

    for (final Schedule time in evaluationTimes) {
      ScheduledTask task = cron.schedule(time, () async {
        _evaluate(routines);
      });
      _scheduledTasks.add(task);
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isWindows || Platform.isLinux) {
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable
      );
    }
    
    _evaluate(routines);
  }

  void _evaluate(List<Routine> routines) {
    routines = routines.where((r) => r.isActive && !r.isPaused && !r.areConditionsMet).toList();

    Set<String> apps = {}; 
    Set<String> sites = {};
    bool allowList = routines.any((r) => r.allow);

    if (allowList) {
      Map<String, int> appCounts = {};
      Map<String, int> siteCounts = {};

      for (final Routine routine in routines) {
        for (final String app in routine.apps) {
          appCounts[app] = (appCounts[app] ?? 0) + 1;
        }
        for (final String site in routine.sites) {
          siteCounts[site] = (siteCounts[site] ?? 0) + 1;
        }
      }

      apps.addAll(appCounts.keys.where((app) => appCounts[app] == routines.length));
      sites.addAll(siteCounts.keys.where((site) => siteCounts[site] == routines.length));
    } else {
      for (final Routine routine in routines) {
        apps.addAll(routine.apps);
        sites.addAll(routine.sites);
      }
    }
    
    // Update cached values
    _cachedSites = sites.toList();
    _cachedApps = apps.toList();
    _isAllowList = allowList;

    // Update both apps and sites
    updateAppList();
    updateBlockedSites();
  }

  void dispose() {
    _socket?.close();
  }

  Future<void> _connectToNMH() async {
    try {
      _socket = await Socket.connect('127.0.0.1', 54322);
      debugPrint('Connected to NMH TCP server');
      _connected = true;

      _socket?.listen(
        (List<int> data) {
          _messageBuffer.addAll(data);
          
          while (_messageBuffer.isNotEmpty) {
            if (_expectedLength == null) {
              if (_messageBuffer.length >= 4) {
                // Read length prefix using Uint8List and ByteData
                final lengthBytes = Uint8List.fromList(_messageBuffer.take(4).toList());
                _expectedLength = ByteData.view(lengthBytes.buffer).getUint32(0, Endian.little);
                _messageBuffer = _messageBuffer.sublist(4);
              } else {
                break;
              }
            }

            if (_expectedLength != null && _messageBuffer.length >= _expectedLength!) {
              // We have a complete message
              final messageBytes = _messageBuffer.take(_expectedLength!).toList();
              _messageBuffer = _messageBuffer.sublist(_expectedLength!);
              _expectedLength = null;

              try {
                final String message = utf8.decode(messageBytes);
                final Map<String, dynamic> decoded = json.decode(message);
                debugPrint('Received from NMH: $decoded');
              } catch (e) {
                debugPrint('Error decoding message: $e');
              }
            } else {
              break;
            }
          }
        },
        onError: (error) {
          debugPrint('Socket error: $error');
          _connected = false;
        },
        onDone: () {
          debugPrint('Socket closed');
          _connected = false;
        },
      );
    } on SocketException catch (e) {
      _connected = false;
      if (e.osError?.errorCode == 61) {
        debugPrint('NMH service is not running. The app will continue without NMH features.');
      } else {
        debugPrint('Socket connection error: ${e.message}. The app will continue without NMH features.');
      }
    }
  }

  void _sendToNMH(String action, Map<String, dynamic> data) {
    if (!_connected) {
      debugPrint('Cannot send to NMH: not connected');
      return;
    }

    try {
      final message = {
        'action': action,
        'data': data,
      };
      
      final String jsonMessage = json.encode(message);
      final List<int> messageBytes = utf8.encode(jsonMessage);
      
      // Send length prefix followed by message
      _socket?.add(Uint8List.fromList([
        ...Uint32List.fromList([messageBytes.length]).buffer.asUint8List(),
        ...messageBytes,
      ]));
      _socket?.flush();
    } catch (e) {
      debugPrint('Failed to send message to NMH: $e');
    }
  }

  Future<void> updateAppList() async {
    // Update platform channel
    platform.invokeMethod('updateAppList', {
      'apps': _cachedApps,
      'allowList': _isAllowList,
    });
  }

  Future<void> updateBlockedSites() async {
    if (!_connected) {
      debugPrint('Not connected to NMH, attempting connection...');
      await _connectToNMH();
      if (!_connected) {
        debugPrint('Failed to connect to NMH, skipping update');
        return;
      }
    }

    // Send update to NMH to forward to browser extension
    _sendToNMH('updateBlockedSites', {
      'sites': _cachedSites,
      'allowList': _isAllowList,
    });
  }

  Future<void> setStartOnLogin(bool enabled) async {
    if (Platform.isWindows || Platform.isLinux) {
      final bool before = await launchAtStartup.isEnabled();
      debugPrint('Setting start on login to $before');
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      final bool result = await launchAtStartup.isEnabled();
      debugPrint('set start on login to $result');
    } else {
      try {
        await platform.invokeMethod('setStartOnLogin', enabled);
      } catch (e) {
        debugPrint('Failed to set start on login: $e');
      }
    }
  }

  Future<bool> getStartOnLogin() async {
    if (Platform.isWindows || Platform.isLinux) {
      final bool enabled = await launchAtStartup.isEnabled();
      debugPrint('Getting start on login status $enabled');
      return enabled;
    } else {
      try {
        final bool enabled = await platform.invokeMethod('getStartOnLogin');
        return enabled;
      } catch (e) {
        debugPrint('Failed to get start on login status: $e');
        return false;
      }
    }
  }

  static Future<List<InstalledApplication>> getInstalledApplications() async {
    List<InstalledApplication> installedApps = [];

    if (Platform.isWindows) {
      // PowerShell command to get installed applications on Windows with their paths
      var result = await Process.run('powershell.exe', [
        '-Command',
      "Get-ItemProperty HKLM:\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*, HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\* | Where-Object DisplayName | Select-Object DisplayName, InstallLocation"      ]);

      if (result.exitCode == 0) {
        String output = result.stdout.toString();
        List<String> lines = output.split('\n');
        String? currentName;
        String? currentPath;

        for (var line in lines) {
          line = line.trim();
          if (line.startsWith('DisplayName')) {
            currentName = line.substring(line.indexOf(':') + 1).trim();
          } else if (line.startsWith('InstallLocation')) {
            currentPath = line.substring(line.indexOf(':') + 1).trim();
            
            if (currentName != null && currentPath.isNotEmpty) {
              installedApps.add(InstalledApplication(
                name: currentName,
                filePath: currentPath,
              ));
            }
            currentName = null;
            currentPath = null;
          }
        }
      }
    } else if (Platform.isMacOS) {  
      // Also check the Applications directory
      Directory appDir = Directory('/Applications');
      if (await appDir.exists()) {
        await for (var entity in appDir.list(recursive: false)) {
          if (entity is Directory && entity.path.endsWith('.app')) {
            String appName = entity.path.split('/').last.replaceAll('.app', '');
            if (!installedApps.any((app) => app.name == appName)) {
              installedApps.add(InstalledApplication(
                name: appName,
                filePath: entity.path,
              ));
            }
          }
        }
      }
    }

    // Sort the list alphabetically by name
    installedApps.sort((a, b) => a.name.compareTo(b.name));
    return installedApps;
  }
}
