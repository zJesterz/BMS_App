import 'package:flutter/material.dart';

import '../models/battery.dart';
import '../services/auth_service.dart';
import '../services/battery_service.dart';
import '../services/history_api_service.dart';
import '../services/mqtt_service.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/settings_panel.dart';
import 'analytics_page.dart';
import 'batteries_page.dart';
import 'history_page.dart';
import 'login_screen.dart';
import 'main_page.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.batteryService, this.authService});

  final BatteryService? batteryService;
  final AuthService? authService;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late BatteryService _batteryService;
  MqttService? _mqttService;
  final _historyApi = HistoryApiService();
  List<Battery> _batteries = [];
  int _selectedPageIndex = 0;
  bool _loadingEvConfig = true;
  bool _mqttConnecting = false;
  bool _mqttConnected = false;
  int _batteryUpdateTick = 0;
  bool _analyticsGraphShown = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _batteryService = widget.batteryService ?? MockBatteryService();
    _initFromFirestore();
  }

  Future<void> _initFromFirestore() async {
    setState(() => _loadingEvConfig = false);
    _loadBatteries();
  }

  /// Publishes BMS config then subscribes to `data/monitoring` for live data.
  Future<void> _startMonitoring({
    required String bms1,
    required String bms2,
  }) async {
    setState(() {
      _mqttConnecting = true;
      _statusMessage = null;
    });

    try {
      final configOk = await MqttService.publishBmsConfig(
        bms1: bms1,
        bms2: bms2,
      );
      if (!configOk) {
        setState(() {
          _mqttConnecting = false;
          _statusMessage = 'Failed to publish BMS config';
        });
        return;
      }

      _mqttService?.dispose();
      if (_batteryService is MqttBatteryService) {
        (_batteryService as MqttBatteryService).dispose();
      }

      final mqttService = MqttService();
      final connected = await mqttService.connectMonitoring();

      if (!connected) {
        mqttService.dispose();
        setState(() {
          _mqttConnecting = false;
          _mqttConnected = false;
          _statusMessage = 'MQTT connection failed';
        });
        return;
      }

      final batteryService = MqttBatteryService(mqttService: mqttService);
      batteryService.onDataUpdated = _onDataUpdated;

      setState(() {
        _mqttService = mqttService;
        _batteryService = batteryService;
        _mqttConnected = true;
        _mqttConnecting = false;
        _statusMessage = 'Connected — waiting for telemetry…';
      });

      _loadBatteries();
    } catch (_) {
      setState(() {
        _mqttConnecting = false;
        _mqttConnected = false;
        _statusMessage = 'MQTT connection failed';
      });
    }
  }

  Future<void> _downloadHistory({
    required DateTime start,
    required DateTime end,
    String? evid,
  }) async {
    await _historyApi.downloadHistory(start: start, end: end, evid: evid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'History downloaded (${start.toLocal()} → ${end.toLocal()})',
        ),
      ),
    );
  }

  void _onDataUpdated() {
    _loadBatteries();
    if (mounted) {
      setState(() {
        _batteryUpdateTick++;
        _statusMessage = 'Receiving live telemetry';
      });
    }
  }

  void _loadBatteries() {
    _batteryService.fetchBatteries().then((list) {
      if (mounted) setState(() => _batteries = list);
    });
  }

  Future<void> _onRefresh() async {
    final list = await _batteryService.fetchBatteries();
    if (mounted) setState(() => _batteries = list);
  }

  void _onNavSelected(int index) {
    setState(() => _selectedPageIndex = index);
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    _mqttService?.dispose();
    if (_batteryService is MqttBatteryService) {
      (_batteryService as MqttBatteryService).dispose();
    }
    await widget.authService?.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingEvConfig) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedPageIndex) {
      case 0:
        return HomePage(batteries: _batteries);
      case 1:
        return BatteriesPage(
          batteryService: _batteryService,
          authService: widget.authService ?? FirebaseAuthService(),
          onRefresh: _onRefresh,
          mqttConnected: _mqttConnected,
          mqttConnecting: _mqttConnecting,
          batteryUpdateTick: _batteryUpdateTick,
        );
      case 2:
        return AnalyticsPage(
          batteries: _batteries,
          mqttConnected: _mqttConnected,
          mqttConnecting: _mqttConnecting,
          statusMessage: _statusMessage,
          onGo: _startMonitoring,
          onDownload: _downloadHistory,
          batteryUpdateTick: _batteryUpdateTick,
          onGraphVisibilityChanged: (shown) {
            setState(() => _analyticsGraphShown = shown);
          },
        );
      case 3:
        return const HistoryPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _mqttService?.dispose();
    if (_batteryService is MqttBatteryService) {
      (_batteryService as MqttBatteryService).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedPageIndex,
        onDestinationSelected: _onNavSelected,
      ),
      endDrawer: const SettingsPanel(),
      appBar: _analyticsGraphShown
          ? null
          : AppBar(
            title: const Text('Battery Monitor'),
            actions: [
          if (_selectedPageIndex == 1 || _selectedPageIndex == 2)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          Builder(
            builder:
                (context) => IconButton(
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
