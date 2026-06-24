import 'package:flutter/material.dart';
import '../utils/about_info.dart';
import '../utils/app_settings.dart';
import '../screens/about_screen.dart';

/// Slide-in settings panel shown from the right (end drawer).
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppSettingsScope.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Panel header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Settings',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable settings list — room for future options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      settings.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: scheme.primary,
                    ),
                    title: const Text('Dark theme'),
                    subtitle: const Text('Use dark appearance across the app'),
                    value: settings.isDarkMode,
                    onChanged: settings.setDarkMode,
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: scheme.primary),
                  title: const Text('About'),
                  subtitle: const Text('Battery Monitor v1.0.0'),
                  onTap: () {
                  Navigator.of(context).pop(); // close drawer
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
                ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
