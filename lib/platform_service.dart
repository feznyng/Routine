import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class PlatformService {
  static const platform = MethodChannel('com.routine.blockedapps');
  static ServerSocket? _server;
  static final Set<Socket> _sockets = {};

  static bool _allowList = false;
  static List<String> _blockedSites = []; 

  static Future<void> startTcpServer() async {
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
  }

  static void dispose() {
    _server?.close();
    for (var socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
  }

  static void _handleConnection(Socket socket) {
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

  static Future<Map<String, dynamic>> _handleMessage(Map<String, dynamic> message) async {
    debugPrint('Received message: $message');
    throw Exception("Not implemented");
  }

  static Future<void> updateLists(List<String> apps, List<String> sites, bool allowList) async {
    try {
      PlatformService._blockedSites = sites;
      PlatformService._allowList = allowList;

      await platform.invokeMethod('updateBlockedApps', {'apps': apps, 'allowList': allowList});
      _sendSitesToNativeHosts();

    } on PlatformException catch (e) {
      debugPrint('Failed to notify native: ${e.message}');
    }
  }

  static void _sendSitesToNativeHosts() {
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

  static void _sendMessageToNativeHosts(Map<String, dynamic> message) {
    var messageBytes = utf8.encode(json.encode(message));
    var lengthBytes = ByteData(4)..setUint32(0, messageBytes.length, Endian.host);
    for (var socket in _sockets) {
      socket.add(lengthBytes.buffer.asUint8List());
      socket.add(messageBytes);
      socket.flush();
    }
  }
}
