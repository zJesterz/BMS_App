import 'package:flutter/material.dart';
import '../models/battery.dart';

class HomePage extends StatelessWidget {
  final List<Battery> batteries;

  const HomePage({super.key, required this.batteries});

  @override
  Widget build(BuildContext context) {
    final totalEVs =
        batteries.map((b) => b.id.split('-').first).toSet().length;

    final connectedCount =
        batteries.where(
              (b) => b.status == BatteryStatus.charging || b.status == BatteryStatus.discharging,
        ).length;

    final unconnectedCount =
        batteries.where(
              (b) => b.status == BatteryStatus.idle || b.status == BatteryStatus.fault,
        ).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _glassCard(
                'Total EVs',
                totalEVs.toString(),
                const Color(0xFF1A6FFF),
              ),
              _glassCard(
                'Total Batteries',
                batteries.length.toString(),
                const Color(0xFF00C97A),
              ),
              _glassCard(
                'Connected Batteries',
                connectedCount.toString(),
                const Color(0xFFFF9F2E),
              ),
              _glassCard(
                'Unconnected Batteries',
                unconnectedCount.toString(),
                const Color(0xFFFF3B30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassCard(String title, String value, Color baseColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.45)!,
            Color.lerp(baseColor, Colors.black, 0.65)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            // ← icon Positioned block is gone
          ],
        ),
      ),
    );
  }
}
