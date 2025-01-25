import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Routine'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _blockedAppsController = TextEditingController();
  final TextEditingController _blockedSitesController = TextEditingController();
  List<String> _blockedApps = [];
  List<String> _blockedSites = [];
  static const platform = MethodChannel('com.routine.blockedapps');
  ServerSocket? _server;
  final Set<Socket> _sockets = {};

  @override
  void initState() {
    super.initState();
    _startTcpServer();
  }

  @override
  void dispose() {
    _blockedAppsController.dispose();
    _blockedSitesController.dispose();
    _server?.close();
    super.dispose();
  }

  Future<void> _startTcpServer() async {
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

  void _handleConnection(Socket socket) {
    _sockets.add(socket);
    debugPrint('New native messaging host connected');

    // Send initial blocked sites list
    var message = {
      'action': 'updateBlockedSites',
      'data': {'sites': _blockedSites}
    };
    
    var messageBytes = utf8.encode(json.encode(message));
    var lengthBytes = ByteData(4)..setUint32(0, messageBytes.length, Endian.host);
    socket.add(lengthBytes.buffer.asUint8List());
    socket.add(messageBytes);
    socket.flush();
    debugPrint('Sent initial blocked sites: $_blockedSites');
    
    // Buffer for length bytes
    List<int> lengthBuffer = [];
    // Buffer for message bytes
    List<int> messageBuffer = [];
    // Expected message length
    int? expectedLength;

    socket.listen(
      (List<int> data) async {
        if (expectedLength == null) {
          // Still collecting length bytes
          lengthBuffer.addAll(data);
          if (lengthBuffer.length >= 4) {
            // We have all 4 bytes for the length
            var bytes = Uint8List.fromList(lengthBuffer.take(4).toList());
            expectedLength = ByteData.view(bytes.buffer).getUint32(0, Endian.host);
            // Start collecting message with any remaining bytes
            messageBuffer.addAll(lengthBuffer.skip(4));
            lengthBuffer.clear();
          }
        } else {
          // Collecting message bytes
          messageBuffer.addAll(data);
        }

        // Check if we have the complete message
        if (expectedLength != null && messageBuffer.length >= expectedLength!) {
          var messageStr = utf8.decode(messageBuffer.take(expectedLength!).toList());
          var message = json.decode(messageStr);
          
          // Handle the message
          var response = await _handleMessage(message);
          
          // Send response
          var responseBytes = utf8.encode(json.encode(response));
          var lengthBytes = ByteData(4)..setUint32(0, responseBytes.length, Endian.host);
          socket.add(lengthBytes.buffer.asUint8List());
          socket.add(responseBytes);
          await socket.flush();

          // Reset for next message
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
    
    switch (message['action']) {
      case 'updateBlockedApps':
        if (message['data']['apps'] is List) {
          setState(() {
            _blockedApps = List<String>.from(message['data']['apps']);
            _blockedAppsController.text = _blockedApps.join(', ');
          });
          return {'action': 'response', 'data': {'status': 'success'}};
        }
        return {'action': 'response', 'data': {'error': 'Invalid apps data'}};
      
      case 'getBlockedApps':
        return {
          'action': 'response',
          'data': {'apps': _blockedApps}
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

  Future<void> _notifyNative(List<String> apps) async {
    try {
      await platform.invokeMethod('updateBlockedApps', {'apps': apps});
    } on PlatformException catch (e) {
      debugPrint('Failed to notify native: ${e.message}');
    }
  }

  void _updateBlockedApps(String input) {
    setState(() {
      _blockedApps = input
          .split(',')
          .map((app) => app.trim())
          .where((app) => app.isNotEmpty)
          .toList();
      _notifyNative(_blockedApps);
    });
  }

  void _updateBlockedSites(String input) {
    setState(() {
      _blockedSites = input
          .split(',')
          .map((site) => site.trim())
          .where((site) => site.isNotEmpty)
          .map((site) => '*://*.$site/*')  // Convert to Chrome match pattern
          .toList();
      
      debugPrint("Updated blocked sites: $_blockedSites");
      // Send updated list to native messaging host
      var message = {
        'action': 'updateBlockedSites',
        'data': {'sites': _blockedSites}
      };
      
      // Send through TCP socket
      if (_server != null) {
        _sendMessageToNativeHosts(message);
        debugPrint('Native messaging host send update');
      } else {
        debugPrint('Native messaging host not connected - skipping update');
      }
    });
  }

  void _sendMessageToNativeHosts(Map<String, dynamic> message) {
    var messageBytes = utf8.encode(json.encode(message));
    var lengthBytes = ByteData(4)..setUint32(0, messageBytes.length, Endian.host);
    _sockets.forEach((socket) {
      socket.add(lengthBytes.buffer.asUint8List());
      socket.add(messageBytes);
      socket.flush();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _blockedAppsController,
              decoration: const InputDecoration(
                labelText: 'Blocked Apps',
                hintText: 'Enter comma-separated app names (e.g., Chrome, Firefox)',
                border: OutlineInputBorder(),
              ),
              onChanged: _updateBlockedApps,
            ),
            const SizedBox(height: 16),
            Text(
              'Currently blocked apps:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _blockedApps
                  .map((app) => Chip(
                        label: Text(app),
                        onDeleted: () {
                          setState(() {
                            _blockedApps.remove(app);
                            _blockedAppsController.text = _blockedApps.join(', ');
                            _notifyNative(_blockedApps);
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _blockedSitesController,
              decoration: const InputDecoration(
                labelText: 'Blocked Sites',
                hintText: 'Enter comma-separated sites (e.g., facebook.com, twitter.com)',
                border: OutlineInputBorder(),
              ),
              onChanged: _updateBlockedSites,
            ),
            const SizedBox(height: 16),
            Text(
              'Currently blocked sites:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _blockedSites
                  .map((site) => Chip(
                        label: Text(site),
                        onDeleted: () {
                          setState(() {
                            _blockedSites.remove(site);
                            _blockedSitesController.text = _blockedSites.join(', ');
                          });
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
