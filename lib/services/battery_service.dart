import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/battery.dart';
import '../models/bms_telemetry.dart';
import 'mqtt_service.dart';

/// Abstract contract for battery data access.
///
/// Swap [MockBatteryService] for an ESP32, REST, or WebSocket implementation
/// without changing UI code.
abstract class BatteryService {
  /// Returns all monitored battery packs.
  Future<List<Battery>> fetchBatteries();

  /// Returns a single battery by [id], or null if not found.
  Future<Battery?> fetchBatteryById(String id);
}

/// Mock implementation backed by static in-memory data.
///
/// Replace this class when wiring real hardware or network sources.
class MockBatteryService implements BatteryService {
  MockBatteryService();

  /// Simulated telemetry store — mirrors what a remote API would return.
  static final List<Battery> _mockBatteries = [
    Battery(
      id: 'battery-1',
      name: 'Main Battery',
      percentage: 85,
      voltage: 48.5,
      current: 12,
      temperature: 32,
      status: BatteryStatus.charging,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    Battery(
      id: 'battery-2',
      name: 'Backup Battery',
      percentage: 62,
      voltage: 47.8,
      current: 9,
      temperature: 29,
      status: BatteryStatus.discharging,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  @override
  Future<List<Battery>> fetchBatteries() async {
    // Simulate a short network/hardware latency.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Battery>.unmodifiable(_mockBatteries);
  }

  @override
  Future<Battery?> fetchBatteryById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      return _mockBatteries.firstWhere((battery) => battery.id == id);
    } on StateError {
      return null;
    }
  }
}

/// Battery service backed by live MQTT telemetry.
///
/// Maintains an in-memory cache of the latest reading for each EV.
/// Pre-populates with [knownIds] so the UI always has something to show
/// even before the first MQTT message arrives.
class MqttBatteryService implements BatteryService {
  final MqttService _mqtt;
  final Map<String, Battery> _cache = {};
  StreamSubscription<BmsTelemetry>? _subscription;

  /// Fires whenever the internal cache is updated.
  VoidCallback? onDataUpdated;

  MqttBatteryService({
    required MqttService mqttService,
    List<String> knownIds = const ['EV001', 'EV002', 'EV003'],
    this.onDataUpdated,
  }) : _mqtt = mqttService {
    for (final id in knownIds) {
      _cache[id] = Battery(
        id: id,
        name: id,
        percentage: 0,
        voltage: 0,
        current: 0,
        temperature: 0,
        status: BatteryStatus.idle,
        lastUpdated: DateTime.now(),
      );
    }
    _subscription = _mqtt.telemetryStream.listen(_onTelemetry);
  }

  void _onTelemetry(BmsTelemetry data) {
    final status = data.current > 0
        ? BatteryStatus.discharging
        : data.current < 0
            ? BatteryStatus.charging
            : BatteryStatus.idle;

    _cache[data.id] = Battery(
      id: data.id,
      name: data.id,
      percentage: data.soc,
      voltage: data.voltage,
      current: data.current.abs(),
      temperature: 0,
      status: status,
      lastUpdated: data.timestamp,
    );
    onDataUpdated?.call();
  }

  @override
  Future<List<Battery>> fetchBatteries() async {
    return _cache.values.toList();
  }

  @override
  Future<Battery?> fetchBatteryById(String id) async {
    return _cache[id];
  }

  void dispose() {
    _subscription?.cancel();
  }
}
