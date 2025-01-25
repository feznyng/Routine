import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _blockedAppsController = TextEditingController();
  List<String> _blockedApps = [];
  static const platform = MethodChannel('com.routine.blockedapps');

  @override
  void dispose() {
    _blockedAppsController.dispose();
    super.dispose();
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
