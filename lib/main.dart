import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/battery_service.dart';
import 'services/mqtt_service.dart';
import 'utils/app_settings.dart';
import 'utils/theme.dart';
void main() {
  final mqttService = MqttService(host: '10.154.52.212');
  mqttService.connect();
  final batteryService = MqttBatteryService(mqttService: mqttService);
  runApp(BatteryMonitorApp(batteryService: batteryService));
}
/// Root application widget.
class BatteryMonitorApp extends StatefulWidget {
  const BatteryMonitorApp({super.key, this.batteryService});
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
        home: LoginScreen(batteryService: widget.batteryService ?? MockBatteryService()),
      ),
    );
  }
}