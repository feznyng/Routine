import 'package:flutter/material.dart';


class GlobalSnackBar {
  static final GlobalKey<ScaffoldMessengerState> _key = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get key => _key;


  static void show(String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (_key.currentState != null) {
      _key.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
        ),
      );
    }
  }
}
