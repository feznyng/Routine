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
  List<String> _blockedApps = [];
  static const platform = MethodChannel('com.routine.blockedapps');
  ServerSocket? _server;

  @override
  void initState() {
    super.initState();
    _startTcpServer();
  }

  @override
  void dispose() {
    _blockedAppsController.dispose();
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
        socket.close();
      },
      onDone: () {
        debugPrint('Native messaging host disconnected');
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
            )
          ],
        ),
      )
    );
  }
}
