import 'package:flutter/material.dart';

import '../models/battery.dart';
import '../services/battery_service.dart';
import '../widgets/metric_tile.dart';

/// Detailed view for a single battery — SOC, voltage, and current only.
class BatteryDetailsScreen extends StatefulWidget {
  const BatteryDetailsScreen({
    super.key,
    required this.batteryId,
    this.batteryService,
  });

  final String batteryId;
  final BatteryService? batteryService;

  @override
  State<BatteryDetailsScreen> createState() => _BatteryDetailsScreenState();
}

class _BatteryDetailsScreenState extends State<BatteryDetailsScreen> {
  late final BatteryService _batteryService;
  late Future<Battery?> _batteryFuture;

  @override
  void initState() {
    super.initState();
    _batteryService = widget.batteryService ?? MockBatteryService();
    _loadBattery();
  }

  void _loadBattery() {
    _batteryFuture = _batteryService.fetchBatteryById(widget.batteryId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Battery Details')),
      body: FutureBuilder<Battery?>(
        future: _batteryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final battery = snapshot.data;
          if (battery == null) {
            return const Center(child: Text('Battery not found'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final horizontalPadding = isWide ? 32.0 : 16.0;
              final maxContentWidth = isWide ? 720.0 : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      32,
                    ),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.battery_full_rounded,
                                size: 56,
                                color: scheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(battery.name, style: theme.textTheme.titleLarge),
                              const SizedBox(height: 20),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: battery.percentage / 100,
                                  minHeight: 12,
                                  backgroundColor: scheme.surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: isWide ? 3 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.3 : 2.4,
                        children: [
                          MetricTile(
                            icon: Icons.battery_5_bar_rounded,
                            label: 'SOC',
                            value: '${battery.percentage.toStringAsFixed(0)}%',
                          ),
                          MetricTile(
                            icon: Icons.bolt_rounded,
                            label: 'Voltage',
                            value: '${battery.voltage.toStringAsFixed(1)} V',
                          ),
                          MetricTile(
                            icon: Icons.electric_bolt_rounded,
                            label: 'Current',
                            value: '${battery.current.toStringAsFixed(0)} A',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
