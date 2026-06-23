import 'package:flutter/material.dart';

/// Left slide-out navigation drawer for switching app pages.
class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const destinations = <({IconData icon, String label})>[
  (icon: Icons.dashboard_rounded, label: 'Dashboard'),
  (icon: Icons.battery_charging_full_rounded, label: 'Batteries'),
  (icon: Icons.analytics_outlined, label: 'Analytics'),
  (icon: Icons.history_rounded, label: 'History'),
];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.battery_charging_full_rounded, color: scheme.primary, size: 32),
              const SizedBox(height: 12),
              Text('Battery Monitor', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Navigation',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < destinations.length; i++)
          NavigationDrawerDestination(
            icon: Icon(destinations[i].icon),
            selectedIcon: Icon(destinations[i].icon),
            label: Text(destinations[i].label),
          ),
      ],
    );
  }
}
