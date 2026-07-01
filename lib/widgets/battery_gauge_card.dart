import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/battery.dart';

class BatteryGaugeCard extends StatelessWidget {
  const BatteryGaugeCard({super.key, required this.battery, this.onTap});

  final Battery battery;
  final VoidCallback? onTap;

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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Circular SOC gauge ──────────────────────────────
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: battery.percentage / 100,
                    color: socColor,
                    trackColor: scheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${battery.percentage.toStringAsFixed(0)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: socColor,
                          ),
                        ),
                        Text(
                          'SOC',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ── Right side: name + metrics ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            battery.name,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: battery.status),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Voltage + Current side by side
                    Row(
                      children: [
                        Expanded(
                          child: _MetricRow(
                            icon: Icons.bolt_rounded,
                            label: 'Voltage',
                            value: '${battery.voltage.toStringAsFixed(1)} V',
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricRow(
                            icon: Icons.electric_bolt_rounded,
                            label: 'Current',
                            value: '${battery.current.toStringAsFixed(1)} A',
                            color: scheme.secondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Last updated
                    Row(
                      children: [
                        Icon(
                          Icons.update_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatUpdated(battery.lastUpdated),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUpdated(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }
}

// ── Circular gauge painter ─────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    const startAngle = math.pi * 0.75;
    const sweepFull = math.pi * 1.5;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - strokeWidth / 2,
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (value > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepFull * value.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ── Metric row ────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BatteryStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (label, color) = switch (status) {
      BatteryStatus.charging => ('Charging', scheme.primary),
      BatteryStatus.discharging => ('Discharging', scheme.secondary),
      BatteryStatus.idle => ('Idle', scheme.tertiary),
      BatteryStatus.fault => ('Fault', scheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
