/// Single pack reading inside a monitoring MQTT message.
class BmsPackReading {
  const BmsPackReading({
    required this.packNumber,
    required this.voltage,
    required this.current,
    required this.soc,
  });

  final int packNumber;
  final double voltage;
  final double current;
  final double soc;
}

/// MQTT monitoring payload from topic `data/monitoring`.
///
/// Example:
/// {
///   "EVID": "EV0001",
///   "1": {"V": 48, "I": 0, "SoC": 68},
///   "2": {"V": 48.3, "I": -4.2, "SoC": 70}
/// }
class MonitoringPayload {
  const MonitoringPayload({
    required this.evid,
    required this.packs,
    required this.receivedAt,
  });

  final String evid;
  final List<BmsPackReading> packs;
  final DateTime receivedAt;

  factory MonitoringPayload.fromJson(Map<String, dynamic> json) {
    final packs = <BmsPackReading>[];

    for (final entry in json.entries) {
      if (entry.key.toUpperCase() == 'EVID') {
        continue;
      }

      final packNumber = int.tryParse(entry.key);
      if (packNumber == null) {
        continue;
      }

      if (entry.value is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(entry.value);

      packs.add(
        BmsPackReading(
          packNumber: packNumber,
          voltage: _toDouble(map['V'] ?? map['Voltage']),
          current: _toDouble(map['I'] ?? map['Current']),
          soc: _toDouble(
            map['SoC'] ??
                map['SOC'] ??
                map['soc'],
          ),
        ),
      );
    }

    packs.sort((a, b) => a.packNumber.compareTo(b.packNumber));

    return MonitoringPayload(
      evid: json['EVID']?.toString() ??
          json['evid']?.toString() ??
          '',
      packs: packs,
      receivedAt: DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  /// Generates a unique battery id.
  static String batteryId(
    String evid,
    int packNumber,
  ) {
    return '$evid-$packNumber';
  }
}