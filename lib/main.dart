import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'desktop_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  // Configure window manager
  const windowOptions = WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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

class _MyHomePageState extends State<MyHomePage> with TrayListener, WindowListener {
  final DesktopService _desktopService = DesktopService();  
  bool _startOnLogin = false;

  @override
  void initState() {
    super.initState();
    _initializeTray();
    windowManager.addListener(this);
    trayManager.addListener(this);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _desktopService.init().then((_) {
        _initializeStartOnLogin();
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initializeTray() async {
    await trayManager.setIcon(
      'assets/app_icon.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          label: 'Show',
          onClick: (menuItem) async {
            await windowManager.show();
          },
        ),
        MenuItem(
          label: 'Exit',
          onClick: (menuItem) async {
            await windowManager.destroy();
          },
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  Future<void> _initializeStartOnLogin() async {
    final enabled = await _desktopService.getStartOnLogin();
    setState(() {
      _startOnLogin = enabled;
    });
  }

  @override
  void onTrayIconMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
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
          children: [
            SwitchListTile(
              title: const Text('Start on Login'),
              value: _startOnLogin,
              onChanged: (bool value) {
                setState(() {
                  _startOnLogin = value;
                });
                _desktopService.setStartOnLogin(value);
              },
            ),
            Text(
              'Tester',
              style: Theme.of(context).textTheme.titleMedium,
            )
          ],
        ),
      ),
    );
  }
}
