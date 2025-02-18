import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/routine_list.dart';
import 'widgets/settings_page.dart';
import 'auth_service.dart';
import 'setup.dart';

// Desktop-specific imports
import 'package:window_manager/window_manager.dart' if (dart.library.html) '';
import 'package:tray_manager/tray_manager.dart' if (dart.library.html) '';
import 'desktop_service.dart' if (dart.library.html) '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize auth service
  await AuthService().initialize();
  
  // Initialize desktop-specific features
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
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
  }

  setup();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
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
  late final bool _isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  int _selectedIndex = 0;
  final List<Widget> _pages = const [
    RoutineList(),
    SettingsPage(),
  ];
  late final DesktopService? _desktopService = _isDesktop ? DesktopService() : null;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      _initializeTray();
      windowManager.addListener(this);
      trayManager.addListener(this);
      _desktopService?.init();
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
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
      body: _isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.schedule),
                      label: Text('Routines'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: !_isDesktop
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.schedule),
                  label: 'Routines',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }
}
