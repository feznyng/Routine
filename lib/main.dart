import 'package:flutter/material.dart';
import 'platform_service.dart';

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

  @override
  void initState() {
    super.initState();
    PlatformService.startTcpServer();
    PlatformService.onBlockedAppsChanged = (apps) {
      setState(() {
        _blockedApps = apps;
        _blockedAppsController.text = _blockedApps.join(', ');
      });
    };
  }

  @override
  void dispose() {
    _blockedAppsController.dispose();
    _blockedSitesController.dispose();
    PlatformService.dispose();
    super.dispose();
  }

  void _updateBlockedApps(String input) {
    setState(() {
      _blockedApps = input
          .split(',')
          .map((app) => app.trim())
          .where((app) => app.isNotEmpty)
          .toList();
      PlatformService.updateBlockedApps(_blockedApps);
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
      PlatformService.updateBlockedSites(_blockedSites);
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
                            PlatformService.updateBlockedApps(_blockedApps);
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
