import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              subtitle: Text('App settings and preferences will be added here'),
            ),
          ),
        ],
      ),
    );
  }
}
