import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BatteryMonitorApp extends StatelessWidget {
  const BatteryMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Monitor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BatteryStatusScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BatteryStatusScreen extends StatefulWidget {
  const BatteryStatusScreen({super.key});

  @override
  State<BatteryStatusScreen> createState() => _BatteryStatusScreenState();
}

class _BatteryStatusScreenState extends State<BatteryStatusScreen> {
  late Timer _timer;
  bool isLoading = false;
  Map<String, String> batteryData = {
    'Voltage': '0V',
    'SOC': '0%',
    'Health': 'Unknown',
  };
  Map<String, String> tempData = {
    'Battery Temp': '0°C',
    'Ambient Temp': '0°C',
  };

  @override
  void initState() {
    super.initState();
    _startFetchingData();
  }

  void _startFetchingData() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final newBatteryData = await _fetchSensorData();
      setState(() {
        batteryData = newBatteryData['battery']!;
        tempData = newBatteryData['temp']!;
      });
    });
  }

  Future<Map<String, Map<String, String>>> _fetchSensorData() async {
    final response = await http.get(Uri.parse('http://<esp32-ip>/sensor'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'battery': {
          'Voltage': data['voltage'] ?? 'N/A',
          'SOC': data['soc'] ?? 'N/A',
          'Health': data['health'] ?? 'N/A',
        },
        'temp': {
          'Battery Temp': data['battery_temp'] ?? 'N/A',
          'Ambient Temp': data['ambient_temp'] ?? 'N/A',
        }
      };
    } else {
      return {
        'battery': {
          'Voltage': 'Error',
          'SOC': 'Error',
          'Health': 'Error',
        },
        'temp': {
          'Battery Temp': 'Error',
          'Ambient Temp': 'Error',
        }
      };
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Battery Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => isLoading = true);
              final newBatteryData = await _fetchSensorData();
              setState(() {
                batteryData = newBatteryData['battery']!;
                tempData = newBatteryData['temp']!;
                isLoading = false;
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusCard(
                    title: 'Battery Status',
                    items: batteryData,
                  ),
                  const SizedBox(height: 20),
                  StatusCard(
                    title: 'Temperature Status',
                    items: tempData,
                  ),
                ],
              ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String title;
  final Map<String, String> items;

  const StatusCard({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...items.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 16)),
                  Text(entry.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(
            child: Text('Menu', style: TextStyle(fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
          ),
        ],
      ),
    );
  }
}