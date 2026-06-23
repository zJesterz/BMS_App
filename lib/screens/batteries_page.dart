import 'package:flutter/material.dart';

import '../models/battery.dart';
import '../services/battery_service.dart';
import '../widgets/battery_metric_group.dart';
import 'battery_details_screen.dart';

/// Primary view — 6 live data points (SOC, voltage, current × 2 batteries).
class BatteriesPage extends StatelessWidget {
  const BatteriesPage({
    super.key,
    required this.batteries,
    required this.batteryService,
    required this.onRefresh,
  });

  final List<Battery> batteries;
  final BatteryService batteryService;
  final Future<void> Function() onRefresh;

  void _openDetails(BuildContext context, Battery battery) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BatteryDetailsScreen(
          batteryId: battery.id,
          batteryService: batteryService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final horizontalPadding = isWide ? 32.0 : 16.0;
          final maxContentWidth = isWide ? 1100.0 : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  24,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live Telemetry', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'SOC, voltage, and current for ${batteries.length} battery packs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWide && batteries.length >= 2)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < batteries.length; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          Expanded(
                            child: BatteryMetricGroup(
                              battery: batteries[i],
                              onTap: () => _openDetails(context, batteries[i]),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    ...batteries.map(
                      (battery) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BatteryMetricGroup(
                          battery: battery,
                          onTap: () => _openDetails(context, battery),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
