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
  ServerSocket? _server;
  final Set<Socket> _sockets = {};

  bool _allowList = false;
  List<String> _blockedSites = []; 

  Future<void> init() async {
    try {
      _server = await ServerSocket.bind('127.0.0.1', 54321);
      debugPrint('TCP Server listening on port 54321');

      _server?.listen((socket) {
        debugPrint('Native messaging host connected');
        _handleConnection(socket);
      });
    } catch (e) {
      debugPrint('Failed to start TCP server: $e');
    }


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

    updateLists(apps, sites, allowList);
  }

  void dispose() {
    _server?.close();
    for (var socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
  }

  void _handleConnection(Socket socket) {
    _sockets.add(socket);
    debugPrint('New native messaging host connected');

    _sendSitesToNativeHosts();

    // Buffer for length bytes
    List<int> lengthBuffer = [];
    // Buffer for message bytes
    List<int> messageBuffer = [];
    // Expected message length
    int? expectedLength;

    socket.listen(
      (List<int> data) async {
        if (expectedLength == null) {
          lengthBuffer.addAll(data);
          if (lengthBuffer.length >= 4) {
            var bytes = Uint8List.fromList(lengthBuffer.take(4).toList());
            expectedLength = ByteData.view(bytes.buffer).getUint32(0, Endian.host);
            messageBuffer.addAll(lengthBuffer.skip(4));
            lengthBuffer.clear();
          }
        } else {
          messageBuffer.addAll(data);
        }

        if (expectedLength != null && messageBuffer.length >= expectedLength!) {
          var messageStr = utf8.decode(messageBuffer.take(expectedLength!).toList());
          var message = json.decode(messageStr);
          
          var response = await _handleMessage(message);
          
          var responseBytes = utf8.encode(json.encode(response));
          var lengthBytes = ByteData(4)..setUint32(0, responseBytes.length, Endian.host);
          socket.add(lengthBytes.buffer.asUint8List());
          socket.add(responseBytes);
          await socket.flush();

          messageBuffer = messageBuffer.sublist(expectedLength!);
          expectedLength = null;
        }
      },
      onError: (error) {
        debugPrint('Socket error: $error');
        _sockets.remove(socket);
        socket.close();
      },
      onDone: () {
        debugPrint('Native messaging host disconnected');
        _sockets.remove(socket);
        socket.close();
      },
    );
  }

  Future<Map<String, dynamic>> _handleMessage(Map<String, dynamic> message) async {
    debugPrint('Received message: $message');
    throw Exception("Not implemented");
  }

  Future<void> updateLists(List<String> apps, List<String> sites, bool allowList) async {
    try {
      _blockedSites = sites;
      _allowList = allowList;

      await platform.invokeMethod('updateBlockedApps', {'apps': apps, 'allowList': allowList});
      _sendSitesToNativeHosts();

    } on PlatformException catch (e) {
      debugPrint('Failed to notify native: ${e.message}');
    }
  }

  void _sendSitesToNativeHosts() {
    var message = {
      'action': 'updateBlockedSites',
      'data': {'sites': _blockedSites, 'allowList': _allowList}
    };
    
    if (_server != null) {
      _sendMessageToNativeHosts(message);
      debugPrint('Native messaging host send update');
    } else {
      debugPrint('Native messaging host not connected - skipping update');
    }
  }

  void _sendMessageToNativeHosts(Map<String, dynamic> message) {
    var messageBytes = utf8.encode(json.encode(message));
    var lengthBytes = ByteData(4)..setUint32(0, messageBytes.length, Endian.host);
    for (var socket in _sockets) {
      socket.add(lengthBytes.buffer.asUint8List());
      socket.add(messageBytes);
      socket.flush();
    }
  }
}
