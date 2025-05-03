import 'dart:io';

import 'package:Routine/models/routine.dart';
import 'package:cron/cron.dart';
import 'package:geolocator/geolocator.dart';

class Util {
  static bool isDesktop() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static String camelToSnake(String input) {
    if (input.isEmpty) return input;
    
    // Start with the first character
    StringBuffer result = StringBuffer(input[0].toLowerCase());
    
    // Process remaining characters
    for (int i = 1; i < input.length; i++) {
      String char = input[i];
      
      // If uppercase letter found, add underscore before it
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
    
    // Split the string by underscores
    List<String> words = input.split('_');
    
    // Convert first word to lowercase
    String result = words[0].toLowerCase();
    
    // Capitalize first letter of remaining words and add them
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

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
      
      // Add a small delay after permission is granted to allow the system to update
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Set<Schedule> getEvaluationTimes(List<Routine> routines) {
    Set<Schedule> evaluationTimes = {};
    for (final Routine routine in routines) {
      evaluationTimes.add(Schedule(hours: routine.startHour, minutes: routine.startMinute, seconds: 10));
      evaluationTimes.add(Schedule(hours: routine.endHour, minutes: routine.endMinute, seconds: 10));

      if (routine.pausedUntil != null && routine.pausedUntil!.isAfter(DateTime.now())) {
        evaluationTimes.add(Schedule(hours: routine.pausedUntil!.hour, minutes: routine.pausedUntil!.minute, seconds: routine.pausedUntil!.second + 5));
      }

      if (routine.snoozedUntil != null && routine.snoozedUntil!.isAfter(DateTime.now())) {
        evaluationTimes.add(Schedule(hours: routine.snoozedUntil!.hour, minutes: routine.snoozedUntil!.minute, seconds: routine.snoozedUntil!.second + 5));
      }
    }
    return evaluationTimes;
  }
}