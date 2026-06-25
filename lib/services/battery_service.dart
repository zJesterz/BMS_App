import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/battery.dart';
import '../models/bms_telemetry.dart';
import 'mqtt_service.dart';

abstract class BatteryService {
  Future<List<Battery>> fetchBatteries();
  Future<Battery?> fetchBatteryById(String id);
}

class MockBatteryService implements BatteryService {
  MockBatteryService();

  static final List<Battery> _mockBatteries = [
    Battery(
      id: 'EV001-B1',
      name: 'EV001 — Pack 1',
      percentage: 85,
      voltage: 48.5,
      current: 12,
      temperature: 32,
      status: BatteryStatus.charging,
      lastUpdated: DateTime.now().subtract(const Duration(seconds: 20)),
    ),
    Battery(
      id: 'EV001-B2',
      name: 'EV001 — Pack 2',
      percentage: 62,
      voltage: 47.8,
      current: 9,
      temperature: 29,
      status: BatteryStatus.discharging,
      lastUpdated: DateTime.now().subtract(const Duration(seconds: 45)),
    ),
    Battery(
      id: 'EV002-B1',
      name: 'EV002 — Pack 1',
      percentage: 41,
      voltage: 46.2,
      current: 0,
      temperature: 27,
      status: BatteryStatus.idle,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    Battery(
      id: 'EV002-B2',
      name: 'EV002 — Pack 2',
      percentage: 18,
      voltage: 44.1,
      current: 0,
      temperature: 31,
      status: BatteryStatus.fault,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  @override
  Future<List<Battery>> fetchBatteries() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Battery>.unmodifiable(_mockBatteries);
  }

  @override
  Future<Battery?> fetchBatteryById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      return _mockBatteries.firstWhere((b) => b.id == id);
    } on StateError {
      return null;
    }
  }
}

/// Battery service backed by live MQTT telemetry.
///
/// Battery IDs are expected in the format "EVXXX-B1", "EVXXX-B2" etc.
/// Pre-populates cache with placeholder entries for all known pack IDs
/// so the UI has something to show before the first MQTT message arrives.
class MqttBatteryService implements BatteryService {
  final MqttService _mqtt;
  final Map<String, Battery> _cache = {};
  StreamSubscription<BmsTelemetry>? _subscription;

  VoidCallback? onDataUpdated;

  MqttBatteryService({
    required MqttService mqttService,
    List<String> knownIds = const [
      'EV001-B1', 'EV001-B2',
      'EV002-B1', 'EV002-B2',
    ],
    this.onDataUpdated,
  }) : _mqtt = mqttService {
    for (final id in knownIds) {
      _cache[id] = Battery(
        id: id,
        name: id.replaceAll('-', ' — '),
        percentage: 0,
        voltage: 0,
        current: 0,
        temperature: 0,
        status: BatteryStatus.fault,
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
      name: data.id.replaceAll('-', ' — '),
      percentage: data.soc,
      voltage: data.voltage,
      current: data.current.abs(),
      temperature: 0,
      status: status,
      lastUpdated: data.timestamp,
    );
    onDataUpdated?.call();
  }

  Battery _flagStale(Battery b) {
    if (DateTime.now().difference(b.lastUpdated).inSeconds > 60) {
      return b.copyWith(status: BatteryStatus.fault);
    }
    return b;
  }

  @override
  Future<List<Battery>> fetchBatteries() async {
    return _cache.values.map(_flagStale).toList();
  }

  @override
  Future<Battery?> fetchBatteryById(String id) async {
    final b = _cache[id];
    return b != null ? _flagStale(b) : null;
  }

  void dispose() {
    _subscription?.cancel();
  }
}