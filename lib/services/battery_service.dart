import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/battery.dart';
import '../models/monitoring_payload.dart';
import 'mqtt_service.dart';

abstract class BatteryService {
  Future<List<Battery>> fetchBatteries();
  Future<Battery?> fetchBatteryById(String id);
}

class MockBatteryService implements BatteryService {
  MockBatteryService();

  static final List<Battery> _mockBatteries = [
    Battery(
      id: 'EV0001-1',
      name: 'EV0001 — Pack 1',
      percentage: 85,
      voltage: 48.5,
      current: 12,
      temperature: 32,
      status: BatteryStatus.charging,
      lastUpdated: DateTime.now().subtract(const Duration(seconds: 20)),
    ),
    Battery(
      id: 'EV0001-2',
      name: 'EV0001 — Pack 2',
      percentage: 62,
      voltage: 47.8,
      current: 9,
      temperature: 29,
      status: BatteryStatus.discharging,
      lastUpdated: DateTime.now().subtract(const Duration(seconds: 45)),
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

/// Battery service backed by live MQTT monitoring on `data/monitoring`.
class MqttBatteryService implements BatteryService {
  MqttBatteryService({
    required MqttService mqttService,
    this.onDataUpdated,
  }) : _mqtt = mqttService {
    _subscription = _mqtt.monitoringStream.listen(_onMonitoring);
  }

  final MqttService _mqtt;
  final Map<String, Battery> _cache = {};
  StreamSubscription<MonitoringPayload>? _subscription;

  VoidCallback? onDataUpdated;

  void _onMonitoring(MonitoringPayload payload) {
    if (payload.evid.isEmpty) return;

    for (final pack in payload.packs) {
      final id = MonitoringPayload.batteryId(payload.evid, pack.packNumber);
      final status =
          pack.current > 0
              ? BatteryStatus.discharging
              : pack.current < 0
              ? BatteryStatus.charging
              : BatteryStatus.idle;

      _cache[id] = Battery(
        id: id,
        name: '${payload.evid} — Pack ${pack.packNumber}',
        percentage: pack.soc,
        voltage: pack.voltage,
        current: pack.current.abs(),
        temperature: 0,
        status: status,
        lastUpdated: payload.receivedAt,
      );
    }

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
    return _cache.values.map(_flagStale).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
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
