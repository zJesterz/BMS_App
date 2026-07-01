/// Represents the operational state of a battery pack.
enum BatteryStatus {
  charging,
  discharging,
  idle,
  fault;

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case BatteryStatus.charging:
        return 'Charging';
      case BatteryStatus.discharging:
        return 'Discharging';
      case BatteryStatus.idle:
        return 'Idle';
      case BatteryStatus.fault:
        return 'Fault';
    }
  }
}

/// Core domain model for a monitored battery pack.
///
/// Designed to map cleanly onto future data sources (ESP32 serial,
/// REST API payloads, or WebSocket telemetry streams).
class Battery {
  const Battery({
    required this.id,
    required this.name,
    required this.percentage,
    required this.voltage,
    required this.current,
    required this.temperature,
    required this.status,
    required this.lastUpdated,
    this.ownerEmail,
  });

  final String id;
  final String name;
  final String? ownerEmail;

  /// State of charge, 0–100 percent.
  final double percentage;

  /// Terminal voltage in volts.
  final double voltage;

  /// Current draw or charge in amperes (positive = discharging).
  final double current;

  /// Cell/pack temperature in degrees Celsius.
  final double temperature;
  final BatteryStatus status;
  final DateTime lastUpdated;

  /// Creates a copy with selective field overrides (useful when live
  /// telemetry updates arrive from a future data layer).
  Battery copyWith({
    String? id,
    String? name,
    double? percentage,
    double? voltage,
    double? current,
    double? temperature,
    BatteryStatus? status,
    DateTime? lastUpdated,
    String? ownerEmail,
  }) {
    return Battery(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      percentage: percentage ?? this.percentage,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      temperature: temperature ?? this.temperature,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() =>
      'Battery(id: $id, name: $name, percentage: $percentage%)';
}
