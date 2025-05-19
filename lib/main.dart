import 'package:Routine/services/platform_service.dart';
import 'package:Routine/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/routine_list.dart';
import 'pages/settings_page.dart';
import 'services/auth_service.dart';
import 'setup.dart';
import 'services/theme_provider.dart';
import 'services/strict_mode_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'services/desktop_service.dart';
import 'services/mobile_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setup();

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'];
      options.tracesSampleRate = 0.1;
      options.profilesSampleRate = 0.1;

      final exclusionList = [
        'ClientException: Bad file descriptor',
        'FormatException: InvalidJWTToken: Invalid value for JWT claim "exp" with value'
      ];

      options.beforeSend = (event, hint) {
        final exceptions = event.exceptions;

        if (exceptions != null && exceptions.where((e) =>
          exclusionList.firstWhere((el) => e.value?.startsWith(el) ?? false, orElse: () => '').isNotEmpty
          ).isNotEmpty) {
          return null;
        }

        return event;
      };
    },
    appRunner: () => runApp(SentryWidget(child: 
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StrictModeService.instance),
      ],
      child: const MyApp(),
    ),
  )),
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
  late final bool _isDesktop = Util.isDesktop();
  late final PlatformService _platService = _isDesktop ? DesktopService() : MobileService();

  int _selectedIndex = 0;
  
  final List<Widget> _pages = const [
    RoutineList(),
    SettingsPage(),
  ];

  // We're using the ChangeNotifier mechanism for StrictModeService
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _platService.init();
   
    if (_isDesktop) {
      _initializeTray();
      windowManager.addListener(this);
      trayManager.addListener(this);
      
      // Use the ChangeNotifier mechanism for UI updates
      StrictModeService.instance.addListener(_updateTrayMenu);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MobileService().checkAndRequestFamilyControlsAuthorization();
      });
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
      AuthService().notifyAppResumed().then((_) {
        _platService.refresh();
      });
    }
  }

  Future<void> _initializeTray() async {
    await trayManager.setIcon(
      'assets/logotransparent1024.png',
    );
        
    Menu menu = Menu(
      items: [
        MenuItem(
          label: 'Open',
          onClick: (menuItem) async {
            await windowManager.show();
          },
        ),
        MenuItem(
          label: 'Exit',
          onClick: (menuItem) async {
            await windowManager.destroy();
          },
          disabled: StrictModeService.instance.effectiveBlockAppExit,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void _updateTrayMenu() async {        
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
          disabled: StrictModeService.instance.effectiveBlockAppExit,
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
    await windowManager.minimize();
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
