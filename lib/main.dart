import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'widgets/routine_list.dart';
import 'widgets/settings_page.dart';
import 'services/auth_service.dart';
import 'setup.dart';
import 'services/sync_service.dart';
import 'services/theme_provider.dart';
import 'services/strict_mode_service.dart';

// Desktop-specific imports
import 'package:window_manager/window_manager.dart' if (dart.library.html) '';
import 'package:tray_manager/tray_manager.dart' if (dart.library.html) '';
import 'services/desktop_service.dart' if (dart.library.html) '';

// iOS-specific imports
import 'services/ios_service.dart' if (dart.library.html) '';

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
  
  // Initialize strict mode service
  await StrictModeService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StrictModeService.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Routine',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
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

class _MyHomePageState extends State<MyHomePage> with TrayListener, WindowListener, WidgetsBindingObserver {
  late final bool _isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  int _selectedIndex = 0;
  final List<Widget> _pages = const [
    RoutineList(),
    SettingsPage(),
  ];
  late final DesktopService? _desktopService = _isDesktop ? DesktopService() : null;
  late final IOSService? _iosService = !_isDesktop ? IOSService() : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isDesktop) {
      _initializeTray();
      windowManager.addListener(this);
      trayManager.addListener(this);
      _desktopService?.init();
      
      // Listen for changes in strict mode status
      StrictModeService.instance.addListener(_updateTrayMenu);
    } else {
      _iosService!.init();
      
      // Request FamilyControls authorization after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Platform.isIOS) {
          _checkFamilyControlsAuthorization();
        }
      });
    }
  }
  
  // Check and request FamilyControls authorization if needed
  Future<void> _checkFamilyControlsAuthorization() async {
    if (_iosService == null) return;
    
    final bool isAuthorized = await _iosService.checkFamilyControlsAuthorization();
    if (!isAuthorized) {
      await _iosService.requestFamilyControlsAuthorization();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isDesktop) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
      StrictModeService.instance.removeListener(_updateTrayMenu);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Notify the auth service that the app has resumed
      AuthService().notifyAppResumed();
      
      // Trigger a sync job when the app resumes
      if (!_isDesktop) {
        SyncService().addJob(SyncJob(remote: false));
      }
    }
  }

  Future<void> _initializeTray() async {
    await trayManager.setIcon(
      'assets/app_icon.png',
    );
    
    // Get the strict mode service to check if app exit is blocked
    final strictModeService = StrictModeService.instance;
    
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
          disabled: strictModeService.effectiveBlockAppExit,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void _updateTrayMenu() async {
    if (!_isDesktop) return;
    
    final strictModeService = StrictModeService.instance;
    
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
          disabled: strictModeService.effectiveBlockAppExit,
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
  Future<void> onWindowClose() async {
    // Check if app exit is blocked in strict mode
    final strictModeService = Provider.of<StrictModeService>(context, listen: false);
    if (strictModeService.effectiveBlockAppExit) {
      // Prevent window from closing
      await windowManager.minimize();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isDesktop
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
      ),
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
