import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AnalyticsPage extends StatefulWidget {
const AnalyticsPage({super.key});
@override
State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
final List<String> bmsOptions = [
'Daly',
'Jiabaida',
];

List<String> selectedBms = [
'Daly',
'Jiabaida',
];

String selectedMetric = 'SOC';

final Map<String, List<FlSpot>> chartData = {
'SOC': [
FlSpot(0, 72),
FlSpot(1, 74),
FlSpot(2, 77),
FlSpot(3, 79),
FlSpot(4, 82),
FlSpot(5, 85),
],
'Voltage': [
FlSpot(0, 46),
FlSpot(1, 46.5),
FlSpot(2, 47),
FlSpot(3, 47.4),
FlSpot(4, 48),
FlSpot(5, 48.5),
],
'Current': [
FlSpot(0, 4),
FlSpot(1, 6),
FlSpot(2, 8),
FlSpot(3, 10),
FlSpot(4, 9),
FlSpot(5, 12),
],
};

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);


return Scaffold(
  body: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: theme.textTheme.headlineMedium,
        ),

        const SizedBox(height: 12),

        MultiSelectDialogField(
          items: bmsOptions
              .map((e) => MultiSelectItem<String>(e, e))
              .toList(),
          title: const Text('Select BMS'),
          buttonText: const Text('Choose BMS'),
          initialValue: selectedBms,
          searchable: false,
          onConfirm: (values) {
            setState(() {
              selectedBms = values.cast<String>();
            });
          },
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: selectedMetric,
          decoration: const InputDecoration(
            labelText: 'Metric',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(
              value: 'SOC',
              child: Text('SOC (%)'),
            ),
            DropdownMenuItem(
              value: 'Voltage',
              child: Text('Voltage (V)'),
            ),
            DropdownMenuItem(
              value: 'Current',
              child: Text('Current (A)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedMetric = value;
              });
            }
          },
        ),

        const SizedBox(height: 12),

        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '$selectedMetric Trend',
                    style: theme.textTheme.titleMedium,
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 5,
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),

                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),

                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                            ),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                            ),
                          ),
                        ),

                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData[selectedMetric]!,
                            isCurved: true,
                            barWidth: 3,
                            dotData: const FlDotData(
                              show: true,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);


}
}
