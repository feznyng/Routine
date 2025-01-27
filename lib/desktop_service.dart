import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'routine.dart';
import 'block_list.dart';
import 'package:cron/cron.dart';
import 'manager.dart';

class DesktopService {
  // Singleton instance
  static final DesktopService _instance = DesktopService();
  
  final cron = Cron();
  final List<ScheduledTask> _scheduledTasks = [];
  final Manager manager = Manager();

  DesktopService();

  static DesktopService get instance => _instance;

  final platform = const MethodChannel('com.routine.blockedapps');
  Socket? _socket;
  bool _connected = false;
  List<int> _messageBuffer = [];
  int? _expectedLength;

  Future<void> init() async {
    await _connectToNMH();

    // Set up platform channel method handler
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'activeApplication':
          final appName = call.arguments as String;
          debugPrint('Currently active application: $appName');
          break;
      }
    });

    Set<Schedule> evaluationTimes = {};
    for (final Routine routine in manager.routines) {
      evaluationTimes.add(Schedule(hours: routine.startHour, minutes: routine.startMinute));
      evaluationTimes.add(Schedule(hours: routine.endHour, minutes: routine.endMinute));
    }

    for (final Schedule time in evaluationTimes) {
      ScheduledTask task = cron.schedule(time, () async {
        _evaluate();
      });
      _scheduledTasks.add(task);
    }

    _evaluate();
  }


  void _evaluate() {
    Set<BlockList> activeBlockLists = {};
    Set<BlockList> activeAllowLists = {};

    for (final Routine routine in manager.routines) {
      if (routine.isActive()) {
        final BlockList blockList = manager.blockLists[routine.blockId]!;
        (blockList.allowList ? activeAllowLists : activeBlockLists).add(blockList);
      }
    }

    List<String> apps = []; 
    List<String> sites = [];
    bool allowList = false;

    if (activeAllowLists.isNotEmpty) {
      allowList = true;

      Map<String, int> appFrequency = {};
      Map<String, int> siteFrequency = {};
      for (final BlockList blockList in activeAllowLists) {
        for (final String app in blockList.apps) {
          appFrequency[app] = appFrequency[app] ?? 0;
          appFrequency[app] = appFrequency[app]! + 1;
        }
        for (final String site in blockList.sites) {
          siteFrequency[site] = siteFrequency[site] ?? 0;
          siteFrequency[site] = siteFrequency[site]! + 1;
        }
      }
      apps = appFrequency.entries.where((entry) => entry.value == activeAllowLists.length).map((entry) => entry.key).toList();
      sites = siteFrequency.entries.where((entry) => entry.value == activeAllowLists.length).map((entry) => entry.key).toList();
    }

    if (activeBlockLists.isNotEmpty) {
      for (final BlockList blockList in activeBlockLists) {
        sites.addAll(blockList.sites);
        apps.addAll(blockList.apps);
      }
    }

    debugPrint("Active apps: $apps");
    debugPrint("Active sites: $sites");
    debugPrint("Allow list: $allowList");

    updateLists(sites, apps, allowList);
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

  Future<void> updateLists(List<String> sites, List<String> apps, bool allowList) async {
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
      'sites': sites,
      'allowList': allowList,
    });
    
    // Update platform channel
    platform.invokeMethod('updateBlockedApps', {
      'apps': apps,
      'allowList': allowList,
    });
  }
}
