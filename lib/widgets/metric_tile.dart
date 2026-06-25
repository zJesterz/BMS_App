import 'package:flutter/material.dart';

/// Reusable metric display tile used on the details screen.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final iconPad = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 22.0;
    final spacer1 = compact ? 8.0 : 12.0;
    final spacer2 = compact ? 2.0 : 4.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(iconPad),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(compact ? 8 : 12),
              ),
              child: Icon(icon, color: scheme.primary, size: iconSize),
            ),
            SizedBox(height: spacer1),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: spacer2),
            Text(
              value,
              style: (compact
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}