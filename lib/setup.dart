import 'dart:io';
import 'dart:isolate';
import 'dart:math';

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
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance; 

final logger = Logger(
  printer: SimplePrinter(
      colors: true,
  ),
);

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final isolateId = Isolate.current.hashCode.toString();
    print('[$isolateId] bg - task: $task with input $inputData');
    
    try {
      print('[$isolateId] bg - attempting sync');
      await dotenv.load(fileName: '.env');
      await AuthService().init(simple: true);
      final db = AppDatabase();
      getIt.registerSingleton<AppDatabase>(db);
      inputData = inputData ?? {'full': false, 'id': null};

      const syncLockKey = 'sync_in_progress';
      const syncLockTimestampKey = 'sync_lock_timestamp';
      const lockTimeoutMs = 30000;
      const pollIntervalMs = 500;
      const maxWaitTimeMs = 60000;
      
      final startWaitTime = DateTime.now().millisecondsSinceEpoch;
      final prefs = SharedPreferencesAsync();
      final random = Random();

      await Future.delayed(Duration(milliseconds: random.nextInt(5) * 100));
      while (true) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final lockTimestamp = await prefs.getInt(syncLockTimestampKey) ?? 0;
        final isLocked = await prefs.getBool(syncLockKey) ?? false;
        final isLockExpired = (currentTime - lockTimestamp) > lockTimeoutMs;
        
        if (!isLocked || isLockExpired) {
          break;
        }
        
        if ((currentTime - startWaitTime) > maxWaitTimeMs) {
          print('[$isolateId] bg - waited too long for sync lock, proceeding anyway');
          break;
        }
        
        print('[$isolateId] bg - waiting for sync lock to be released...');
        await Future.delayed(Duration(milliseconds: pollIntervalMs));
      }
      
      print('[$isolateId] bg - acquired sync lock, starting sync');
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setBool(syncLockKey, true);
      await prefs.setInt(syncLockTimestampKey, currentTime);
      
      try {
        final syncService = SyncService();
        final result = await syncService.sync(full: inputData['full'], id: inputData['id']);
        syncService.dispose();
        print('[$isolateId] bg - sync completed with result: $result');
        return result;
      } finally {
        await prefs.setBool(syncLockKey, false);
        await prefs.remove(syncLockTimestampKey);
        print('[$isolateId] bg - sync lock released');
      }
    } catch (e) {
      print('[$isolateId] bg - failed to complete sync due to $e');
      try {
        final prefs = SharedPreferencesAsync();
        await prefs.setBool('sync_in_progress', false);
        await prefs.remove('sync_lock_timestamp');
      } catch (lockError) {
        print('[$isolateId] bg - failed to release sync lock: $lockError');
      }
      return Future.value(false);
    }
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

  if (!Util.isDesktop()) {
    await Workmanager().initialize(callbackDispatcher);
  }

  await Future.wait([
    () async {
      final db = AppDatabase();
      getIt.registerSingleton<AppDatabase>(db);

      final currDevice = await Device.getCurrent();
      getIt.registerSingleton<Device>(currDevice); 
    }(),
    AuthService().init()
  ]);

  await Future.wait([
    StrictModeService().init(), 
    SyncService().queueSync()
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

  print("startup in ${stopwatch.elapsed}ms");
}