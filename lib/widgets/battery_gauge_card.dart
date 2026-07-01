import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/battery.dart';

class BatteryGaugeCard extends StatelessWidget {
  const BatteryGaugeCard({super.key, required this.battery, this.onTap});

  final Battery battery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnimatedGauge(battery: battery),
              const SizedBox(width: 20),
              Expanded(child: _StaticInfo(battery: battery)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Smooth gauge with animated SOC ────────────────────────────────────────

class _AnimatedGauge extends StatelessWidget {
  const _AnimatedGauge({required this.battery});

  final Battery battery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final socColor = _socColor(scheme, battery.percentage);

    return RepaintBoundary(
      child: SizedBox(
        width: 120,
        height: 120,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: battery.percentage, end: battery.percentage),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return CustomPaint(
              painter: _GaugePainter(
                value: value / 100,
                color: socColor,
                trackColor: scheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: socColor,
                      ),
                    ),
                    Text(
                      'SOC',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _socColor(ColorScheme scheme, double percentage) {
    if (percentage <= 20) return scheme.error;
    if (percentage <= 40) return scheme.tertiary;
    return scheme.primary;
  }
}

// ── Static info section (name, metrics, timestamp) ───────────────────────

class _StaticInfo extends StatelessWidget {
  const _StaticInfo({required this.battery});

  final Battery battery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          battery.name,
          style: theme.textTheme.titleSmall,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SimpleMetric(
                label: 'Voltage',
                value: '${battery.voltage.toStringAsFixed(1)} V',
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SimpleMetric(
                label: 'Current',
                value: '${battery.current.toStringAsFixed(1)} A',
                color: scheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        RepaintBoundary(
          child: _UpdatedTime(lastUpdated: battery.lastUpdated),
        ),
      ],
    );
  }
}

// ── Simple metric row ───────────────────────────────────────────────────

class _SimpleMetric extends StatelessWidget {
  const _SimpleMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Updated time ─────────────────────────────────────────────────────────

class _UpdatedTime extends StatelessWidget {
  const _UpdatedTime({required this.lastUpdated});

  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          Icons.update_rounded,
          size: 12,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          _formatUpdated(lastUpdated),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
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
