import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Routine/services/auth_service.dart';
import 'package:Routine/services/strict_mode_service.dart';
import 'package:Routine/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'database/database.dart';
import 'package:get_it/get_it.dart';
import 'models/device.dart';
import 'services/sync_service.dart';
import 'package:workmanager/workmanager.dart';

final getIt = GetIt.instance; 

final logger = Logger(
  printer: PrettyPrinter(
      methodCount: 2, 
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    logger.i("bg - task: $task with input $inputData");

    try {
      logger.i("bg - attempting sync");
      
      await dotenv.load(fileName: '.env');

      await AuthService().init(simple: true);

      final db = AppDatabase();
      getIt.registerSingleton<AppDatabase>(db);

      return await SyncService.simple().sync(full: (inputData ?? {'full': false})['full']);
    } catch (e) {
      logger.e("bg - failed to complete sync due to $e");
      return Future.value(false);
    }
  });
}

Future<void> setup() async {
  await dotenv.load(fileName: '.env');

  Workmanager().initialize(
    callbackDispatcher, // The top level function, aka callbackDispatcher
    isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);
    
  await AuthService().init();
  await StrictModeService().init();

  final currDevice = await Device.getCurrent();

  getIt.registerSingleton<Device>(currDevice); 

  await db.initialize();

  await SyncService().queueSync();


  if (kReleaseMode) {
    Logger.level = Level.warning;
  } else {
    Logger.level = Level.trace;
  }
  
  if (Util.isDesktop()) {
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

    if (Platform.isWindows) {
      await WindowsSingleInstance.ensureSingleInstance([], "routine");
    }
  }
}