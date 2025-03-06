import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';

class ThemeSettingsSection extends StatelessWidget {
  const ThemeSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => ListTile(
          title: const Text('Theme'),
          leading: Icon(
            themeProvider.isSystemMode
                ? Icons.brightness_auto
                : themeProvider.isDarkMode
                    ? Icons.dark_mode
                    : Icons.light_mode,
          ),
          trailing: DropdownButton<ThemeMode>(
            value: themeProvider.themeMode,
            underline: const SizedBox(),
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                themeProvider.setThemeMode(newMode);
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System Default'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light Mode'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark Mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
