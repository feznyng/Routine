import 'dart:io';
import 'dart:isolate';

import 'package:routine_blocker/desktop_logger.dart';
import 'package:routine_blocker/services/notification_service.dart'; // WINDOWS:REMOVE
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:routine_blocker/services/auth_service.dart';
import 'package:routine_blocker/services/strict_mode_service.dart';
import 'package:routine_blocker/util.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance; 

final logger = Logger(
  printer: Util.isDesktop() ? DesktopLogger() : SimplePrinter(colors: false),
);

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final isolateId = Isolate.current.hashCode.toString();
    logger.i('[$isolateId] bg - task: $task with input $inputData');
    
    bool success = false;
  
    try {
      logger.i('[$isolateId] bg - attempting sync');
      await dotenv.load(fileName: '.env');
      await AuthService().init(simple: true);
      final db = AppDatabase();
      getIt.registerSingleton<AppDatabase>(db);
      inputData = inputData ?? {'full': false, 'id': null};

      const syncLockKey = 'sync_in_progress';
      const syncLockTimestampKey = 'sync_lock_timestamp';
      const syncTimestampKey = 'sync_latest_started_at';
      const lockTimeoutMs = 30000;
      const pollIntervalMs = 500;
      const maxWaitTimeMs = 60000;

      final prefs = SharedPreferencesAsync();
      final startTime = DateTime.now().millisecondsSinceEpoch;
      prefs.setInt(syncTimestampKey, startTime);

      if ((await prefs.getInt(syncTimestampKey) ?? 0) > startTime) {
        return Future.value(false);
      }
      
      final startWaitTime = DateTime.now().millisecondsSinceEpoch;
      
      while (true) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final lockTimestamp = await prefs.getInt(syncLockTimestampKey) ?? 0;
        final isLocked = await prefs.getBool(syncLockKey) ?? false;
        final isLockExpired = (currentTime - lockTimestamp) > lockTimeoutMs;
        
        if (!isLocked || isLockExpired) {
          break;
        }
        
        if ((currentTime - startWaitTime) > maxWaitTimeMs) {
          logger.i('[$isolateId] bg - waited too long for sync lock, proceeding anyway');
          break;
        }
        
        await Future.delayed(Duration(milliseconds: pollIntervalMs));
      }
      
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setBool(syncLockKey, true);
      await prefs.setInt(syncLockTimestampKey, currentTime);
      
      try {
        final syncService = SyncService();
        success = await syncService.sync(full: inputData['full'], id: inputData['id']);
        syncService.dispose();
        logger.i('[$isolateId] bg - sync completed with result: $success');
      } finally {
        await prefs.setBool(syncLockKey, false);
        await prefs.remove(syncLockTimestampKey);
      }
    } catch (e) {
      logger.i('[$isolateId] bg - failed to complete sync due to $e');
      try {
        final prefs = SharedPreferencesAsync();
        await prefs.setBool('sync_in_progress', false);
        await prefs.remove('sync_lock_timestamp');
      } catch (lockError) {
        logger.i('[$isolateId] bg - failed to release sync lock: $lockError');
      }
    }

    return Future.value(success);
  });
}

Future<void> setup() async {
  if (kReleaseMode) {
    Logger.level = Level.warning;
  } else {
    Logger.level = Level.trace;
  }

  final stopwatch = Stopwatch();
  stopwatch.start();

  await dotenv.load(fileName: '.env');

  await Future.wait([
    () async {
      final db = AppDatabase();
      getIt.registerSingleton<AppDatabase>(db);

      final currDevice = await Device.getCurrent();
      getIt.registerSingleton<Device>(currDevice); 
    }(),
    AuthService().init()
  ]);

  if (!Util.isDesktop()) {
    await Workmanager().initialize(callbackDispatcher);
    await NotificationService().init(); // WINDOWS:REMOVE
  }

  await Future.wait([
    StrictModeService().init(), 
    SyncService().queueSync('startup')
  ]);
  
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

  logger.i("startup in ${stopwatch.elapsed}ms");
}