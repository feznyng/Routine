import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class PlatformService {
  static const platform = MethodChannel('com.routine.blockedapps');
  static ServerSocket? _server;
  static final Set<Socket> _sockets = {};
  static Function(List<String>)? onBlockedAppsChanged;
  static Function(List<String>)? onBlockedSitesChanged;

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
    
    switch (message['action']) {
      case 'updateBlockedApps':
        if (message['data']['apps'] is List) {
          final apps = List<String>.from(message['data']['apps']);
          onBlockedAppsChanged?.call(apps);
          return {'action': 'response', 'data': {'status': 'success'}};
        }
        return {'action': 'response', 'data': {'error': 'Invalid apps data'}};
      
      case 'getBlockedApps':
        return {
          'action': 'response',
          'data': {'apps': []} // This will be populated by the UI
        };
      case 'ping':
        return {
          'action': 'response',
          'data': 'pong'
        };

      default:
        return {
          'action': 'response',
          'data': {'error': 'Unknown action'}
        };
    }
  }

  static Future<void> updateBlockedApps(List<String> apps) async {
    try {
      await platform.invokeMethod('updateBlockedApps', {'apps': apps});
    } on PlatformException catch (e) {
      debugPrint('Failed to notify native: ${e.message}');
    }
  }

  static void updateBlockedSites(List<String> sites) {
    var message = {
      'action': 'updateBlockedSites',
      'data': {'sites': sites}
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
