import 'package:flutter/material.dart';

import '../models/battery.dart';
import '../services/auth_service.dart';
import '../services/battery_service.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/settings_panel.dart';
import 'analytics_page.dart';
import 'batteries_page.dart';
import 'history_page.dart';
import 'login_screen.dart';
import 'main_page.dart';

/// Post-login shell with left navigation drawer and shared app bar.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    this.batteryService,
    this.authService,
  });

  final BatteryService? batteryService;
  final AuthService? authService;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final BatteryService _batteryService;
  List<Battery> _batteries = [];
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _batteryService = widget.batteryService ?? MockBatteryService();

    if (_batteryService case MqttBatteryService mqttService) {
      mqttService.onDataUpdated = _onDataUpdated;
    }

    _loadBatteries();
  }

  void _onDataUpdated() {
    _loadBatteries();
  }

  void _loadBatteries() {
    _batteryService.fetchBatteries().then((list) {
      if (mounted) {
        setState(() => _batteries = list);
      }
    });
  }

  Future<void> _onRefresh() async {
    final list = await _batteryService.fetchBatteries();
    if (mounted) {
      setState(() => _batteries = list);
    }
  }

  void _onNavSelected(int index) {
    setState(() => _selectedPageIndex = index);
    Navigator.of(context).pop(); // Close the drawer after selection.
  }

  Future<void> _logout() async {
    await widget.authService?.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
    );
  }

  Widget _buildBody() {
  switch (_selectedPageIndex) {
    case 0:
      return HomePage(batteries: _batteries);

    case 1:
      return BatteriesPage(
        batteries: _batteries,
        batteryService: _batteryService,
        onRefresh: _onRefresh,
      );

    case 2:
      return const AnalyticsPage();

    case 3:
      return const HistoryPage();

    default:
      return const SizedBox.shrink();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedPageIndex,
        onDestinationSelected: _onNavSelected,
      ),
      endDrawer: const SettingsPanel(),
      appBar: AppBar(
        title: const Text('Battery Monitor'),
        actions: [
          if (_selectedPageIndex == 1)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Settings',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: const Icon(Icons.settings_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
