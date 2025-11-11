import 'dart:io';

import 'package:Routine/models/routine.dart';
import 'package:Routine/setup.dart';
import 'package:cron/cron.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Util {
  static bool isDesktop() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static String camelToSnake(String input) {
    if (input.isEmpty) return input;
    StringBuffer result = StringBuffer(input[0].toLowerCase());
    for (int i = 1; i < input.length; i++) {
      String char = input[i];
      if (char == char.toUpperCase()) {
        result.write('_');
        result.write(char.toLowerCase());
      } else {
        result.write(char);
      }
    }
    
    return result.toString();
  }

  static String snakeToCamel(String input) {
    if (input.isEmpty) return input;
    List<String> words = input.split('_');
    String result = words[0].toLowerCase();
    for (int i = 1; i < words.length; i++) {
      String word = words[i];
      if (word.isNotEmpty) {
        result += word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
    }
    
    return result;
  }

  static bool isBeforeToday(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dateTime.isBefore(today);
  }

  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      await Future.delayed(const Duration(milliseconds: 500));

      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    LocationSettings settings = LocationSettings(accuracy: LocationAccuracy.best);
    return await Geolocator.getCurrentPosition(locationSettings: settings);
  }

  static List<Schedule> _getEvaluationTimes(List<Routine> routines) {
    List<Schedule> evaluationTimes = [];
    Set<int> seen = {}; // dedupe times (minutes) to avoid redundant evals
    _addIfUnseen(evaluationTimes, seen, 0, 0, 0);

    for (final Routine routine in routines) {
      if (routine.allDay) { continue; }

      _addIfUnseen(evaluationTimes, seen, routine.startHour, routine.startMinute, 1);
      _addIfUnseen(evaluationTimes, seen, routine.endHour, routine.endMinute, 1);

      if (routine.pausedUntil != null) {
        _addIfUnseen(evaluationTimes, seen, routine.pausedUntil!.hour, routine.pausedUntil!.minute, routine.pausedUntil!.second + 1);
      }
      if (routine.snoozedUntil != null) {
        _addIfUnseen(evaluationTimes, seen, routine.snoozedUntil!.hour, routine.snoozedUntil!.minute, routine.snoozedUntil!.second + 1);
      }
    }
    
    return evaluationTimes;
  }

  static void scheduleEvaluationTimes(
    List<Routine> routines, 
    List<ScheduledTask> scheduledTasks,
    Future<void> Function() eval,
    ) async {
    final List<Schedule> evaluationTimes = _getEvaluationTimes(routines);

    for (final ScheduledTask task in scheduledTasks) {
      task.cancel();
    }
    scheduledTasks.clear();

    for (final Schedule time in evaluationTimes) {
      ScheduledTask task = Cron().schedule(time, () async {
        await eval();
      });

      scheduledTasks.add(task);
    }
  }

  static void _addIfUnseen(List<Schedule> schedules, Set<int> seen, int hour, int minute, int second) {
    final time = hour * 60 + minute;
    if (!seen.contains(time)) {
      seen.add(time);
      schedules.add(Schedule(hours: hour, minutes: minute, seconds: second + 5)); // add a little delay to avoid timing issues
    }
  }

  static void report(String context, dynamic e, StackTrace? st) {
    logger.e("$context: ${e.toString()}");

    final Hint hint = Hint();
    hint.set('error-context', context);

    Sentry.captureException(
      e,
      stackTrace: st,
      hint: hint
    );
  }
}