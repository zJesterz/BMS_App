import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/battery_service.dart';
import 'utils/app_settings.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BatteryMonitorApp());
}

class BatteryMonitorApp extends StatefulWidget {
  const BatteryMonitorApp({super.key, this.authService, this.batteryService});
  final AuthService? authService;
  final BatteryService? batteryService;

  @override
  State<BatteryMonitorApp> createState() => _BatteryMonitorAppState();
}

class _BatteryMonitorAppState extends State<BatteryMonitorApp> {
  bool _isDarkMode = false;

  void _setDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      isDarkMode: _isDarkMode,
      setDarkMode: _setDarkMode,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Battery Monitor',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: LoginScreen(
          authService: widget.authService,
          batteryService: widget.batteryService,
        ),
      ),
    );
  }
}
