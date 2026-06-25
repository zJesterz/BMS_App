import 'package:flutter/material.dart';

import '../models/battery.dart';
import 'metric_tile.dart';

/// Three core metrics (SOC, voltage, current) for one battery pack.
class BatteryMetricGroup extends StatelessWidget {
  const BatteryMetricGroup({
    super.key,
    required this.battery,
    this.onTap,
    this.compact = false,
  });

  final Battery battery;
  final VoidCallback? onTap;
  final bool compact;

  Color _socColor(ColorScheme scheme) {
    if (battery.percentage <= 20) return scheme.error;
    if (battery.percentage <= 40) return scheme.tertiary;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final socColor = _socColor(scheme);
    final pad = compact ? 14.0 : 20.0;
    final barHeight = compact ? 6.0 : 8.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.battery_std_rounded,
                    color: scheme.primary,
                    size: compact ? 18 : 24,
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Expanded(
                    child: Text(
                      battery.name,
                      style: compact
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleMedium,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                      size: compact ? 18 : 24,
                    ),
                ],
              ),
              SizedBox(height: compact ? 10 : 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: battery.percentage / 100,
                  minHeight: barHeight,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(socColor),
                ),
              ),
              SizedBox(height: compact ? 10 : 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.battery_5_bar_rounded,
                      label: 'SOC',
                      value: '${battery.percentage.toStringAsFixed(0)}%',
                      compact: compact,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.bolt_rounded,
                      label: 'Voltage',
                      value: '${battery.voltage.toStringAsFixed(1)} V',
                      compact: compact,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.electric_bolt_rounded,
                      label: 'Current',
                      value: '${battery.current.toStringAsFixed(0)} A',
                      compact: compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}