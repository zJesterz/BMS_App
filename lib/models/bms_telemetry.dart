class BmsTelemetry {
  final String id;
  final double soc;
  final double voltage;
  final double current;
  final DateTime timestamp;

  const BmsTelemetry({
    required this.id,
    required this.soc,
    required this.voltage,
    required this.current,
    required this.timestamp,
  });

  factory BmsTelemetry.fromJson(Map<String, dynamic> json) {
    return BmsTelemetry(
      id: json['id'] as String,
      soc: (json['soc'] as num).toDouble(),
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}
