import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/battery.dart';
import '../services/auth_service.dart';
import '../services/battery_service.dart';
import '../services/ev_service.dart';
import '../services/mqtt_service.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/settings_panel.dart';
import 'analytics_page.dart';
import 'batteries_page.dart';
import 'history_page.dart';
import 'login_screen.dart';
import 'main_page.dart';

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
  late BatteryService _batteryService;
  MqttService? _mqttService;
  List<Battery> _batteries = [];
  int _selectedPageIndex = 0;
  bool _loadingEvConfig = true;
  bool _mqttConnecting = false;
  bool _mqttConnected = false;
  int _batteryUpdateTick = 0;

  @override
  void initState() {
    super.initState();
    _batteryService = widget.batteryService ?? MockBatteryService();
    _initFromFirestore();
  }

  Future<void> _initFromFirestore() async {
    setState(() => _loadingEvConfig = false);
  }

  Future<void> _startMqtt(String evId) async {
    setState(() => _mqttConnecting = true);
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      final evs = email != null
          ? await EvService().getEvsForUser(email)
          : <EvConfig>[];

      final config = evs.firstWhere(
        (e) => e.evid == evId,
        orElse: () => evs.isNotEmpty
            ? evs.first
            : EvConfig(
                evid: evId,
                mqttClient: '',
                mqttUsername: '',
                mqttPassword: '',
                iotEndpoint: '',
              ),
      );

      final uri = Uri.tryParse(config.iotEndpoint);
      final host =
          (uri?.host.isNotEmpty ?? false) ? uri!.host : config.iotEndpoint;
      final port = (uri?.port ?? 0) != 0 ? uri!.port : 1883;

      _mqttService?.disconnect();

      final mqttService = MqttService(host: host, port: port);
      await mqttService.connect(
        username:
            config.mqttUsername.isNotEmpty ? config.mqttUsername : null,
        password:
            config.mqttPassword.isNotEmpty ? config.mqttPassword : null,
        clientId:
            config.mqttClient.isNotEmpty ? config.mqttClient : null,
      );

      final batteryService = MqttBatteryService(mqttService: mqttService);
      batteryService.onDataUpdated = _onDataUpdated;

      setState(() {
        _mqttService = mqttService;
        _batteryService = batteryService;
        _mqttConnected = mqttService.isConnected;
        _mqttConnecting = false;
      });

      _loadBatteries();
    } catch (_) {
      setState(() {
        _mqttConnecting = false;
        _mqttConnected = false;
      });
    }
  }

  void _onDataUpdated() {
    _loadBatteries();
    if (mounted) setState(() => _batteryUpdateTick++);
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
    _mqttService?.disconnect();
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
          onStartMqtt: _startMqtt,
          batteryUpdateTick: _batteryUpdateTick,
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
  void dispose() {
    _mqttService?.dispose();
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