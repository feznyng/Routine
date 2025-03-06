import 'package:flutter/material.dart';
import '../lib/services/ios_service.dart';

/// A simple test widget to verify that the iOS service works
class TestIOSService extends StatefulWidget {
  const TestIOSService({Key? key}) : super(key: key);

  @override
  State<TestIOSService> createState() => _TestIOSServiceState();
}

class _TestIOSServiceState extends State<TestIOSService> {
  bool _isWatching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test iOS Service'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isWatching 
                ? 'iOS Service is watching routines'
                : 'iOS Service is not watching routines',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_isWatching) {
                  IOSService.instance.stopWatchingRoutines();
                } else {
                  IOSService.instance.startWatchingRoutines();
                }
                setState(() {
                  _isWatching = !_isWatching;
                });
              },
              child: Text(_isWatching ? 'Stop Watching' : 'Start Watching'),
            ),
          ],
        ),
      ),
    );
  }
}
