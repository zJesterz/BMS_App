import 'package:flutter/material.dart';
import '../models/battery.dart';
import '../models/history_event.dart';

class HistoryPage extends StatelessWidget {
  final List<Battery> batteries;
  final List<HistoryEvent> events;

  const HistoryPage({
    super.key,
    required this.batteries,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 20),

          Text('Latest Readings', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          if (batteries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No battery data available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                headingRowHeight: 36,
                dataTextStyle: theme.textTheme.labelMedium,
                columns: [
                  DataColumn(label: Text('Battery', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('SOC')),
                  DataColumn(label: Text('Voltage')),
                  DataColumn(label: Text('Current')),
                ],
                rows: batteries.map((b) {
                  return DataRow(cells: [
                    DataCell(Text(b.name)),
                    DataCell(Text('${b.percentage.toStringAsFixed(0)}%')),
                    DataCell(Text('${b.voltage.toStringAsFixed(1)} V')),
                    DataCell(Text('${b.current.toStringAsFixed(1)} A')),
                  ]);
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          Text('Event Log', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 48, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'No events recorded yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...events.map((event) => _EventTile(event: event, scheme: scheme)),
        ],
      ),
    );
  }

}

class _EventTile extends StatelessWidget {
  final HistoryEvent event;
  final ColorScheme scheme;

  const _EventTile({required this.event, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = DateTime.now().difference(event.timestamp);
    final timeAgo = diff.inSeconds < 60
        ? '${diff.inSeconds}s ago'
        : diff.inMinutes < 60
            ? '${diff.inMinutes}m ago'
            : diff.inHours < 24
                ? '${diff.inHours}h ago'
                : '${diff.inDays}d ago';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(event.icon, color: event.color, size: 20),
          ),
          title: Text(event.title, style: theme.textTheme.titleSmall),
          subtitle: Text(
            event.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          trailing: Text(
            timeAgo,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
