import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io';
import 'manager.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  
  // // Initialize window_manager
  // await windowManager.ensureInitialized();
  
  // // Configure window options
  // WindowOptions windowOptions = const WindowOptions(
  //   size: Size(800, 600),
  //   skipTaskbar: true, // Hide from taskbar
  //   titleBarStyle: TitleBarStyle.hidden,
  // );
  
  // await windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   if (Platform.isMacOS) {
  //     await windowManager.hide();
  //   }
  // });

  // // Initialize tray
  // // await trayManager.setIcon(
  // //   Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
  // // );
  
  // Menu menu = Menu(
  //   items: [
  //     MenuItem(
  //       label: 'Show',
  //       onClick: (_) async {
  //         await windowManager.show();
  //       },
  //     ),
  //     MenuItem(
  //       label: 'Hide',
  //       onClick: (_) async {
  //         await windowManager.hide();
  //       },
  //     ),
  //     MenuItem.separator(),
  //     MenuItem(
  //       label: 'Quit',
  //       onClick: (_) async {
  //         await windowManager.destroy();
  //       },
  //     ),
  //   ],
  // );
  
  // await trayManager.setContextMenu(menu);
  
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

class _MyHomePageState extends State<MyHomePage> with TrayListener {
  Manager manager = Manager();

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    if (Platform.isMacOS) {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
      } else {
        await windowManager.show();
      }
    }
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
