import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../models/battery.dart';

class _BarLabel {
  final String batteryId;
  final String metric;
  _BarLabel(this.batteryId, this.metric);
}

class AnalyticsPage extends StatefulWidget {
  final List<Battery> batteries;
  final bool mqttConnected;
  final bool mqttConnecting;
  final String? statusMessage;
  final int batteryUpdateTick;
  final Future<void> Function({
    required String bms1,
    required String bms2,
  })? onGo;
  final Future<void> Function({
    required DateTime start,
    required DateTime end,
    String? evid,
  })? onDownload;
  final void Function(bool)? onGraphVisibilityChanged;

  const AnalyticsPage({
    super.key,
    required this.batteries,
    this.mqttConnected = false,
    this.mqttConnecting = false,
    this.statusMessage,
    this.batteryUpdateTick = 0,
    this.onGo,
    this.onDownload,
    this.onGraphVisibilityChanged,
  });
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final List<String> bmsOptions = ['Daly', 'Jiabaida'];
  String _bms1 = 'Daly';
  String _bms2 = 'Daly';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();
  bool _downloading = false;

  final List<String> metricOptions = ['SOC', 'Voltage', 'Current'];
  List<String> selectedMetrics = ['SOC', 'Voltage', 'Current'];
  List<String> selectedBatteryIds = [];

  bool _showGraph = false;

  final Map<String, List<FlSpot>> chartData = {};
  int _timeIndex = 0;

  final _random = Random();
  final Map<String, Map<String, double>> _lastValues = {};
  Timer? _mockTimer;
  final List<_BarLabel> _barLabels = [];
  static const int _maxPoints = 100;
  static const int _windowSize = 20;

  @override
  void initState() {
    super.initState();
    _seedInitialData();
    if (!widget.mqttConnected) {
      _startMockData();
    }
  }

  @override
  void didUpdateWidget(AnalyticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mqttConnected && !oldWidget.mqttConnected) {
      _mockTimer?.cancel();
      _mockTimer = null;
    }
    if (widget.mqttConnected &&
        widget.batteryUpdateTick != oldWidget.batteryUpdateTick) {
      _appendLiveData();
    }
  }

  void _appendLiveData() {
    if (widget.batteries.isEmpty) return;
    setState(() {
      for (final b in widget.batteries) {
        _lastValues[b.id] = {
          'SOC': b.percentage,
          'Voltage': b.voltage,
          'Current': b.current,
        };
        for (final metric in ['SOC', 'Voltage', 'Current']) {
          final key = '${b.id}|$metric';
          chartData.putIfAbsent(key, () => []);
          chartData[key]!.add(FlSpot(_timeIndex.toDouble(), _lastValues[b.id]![metric]!));
          if (chartData[key]!.length > _maxPoints) {
            chartData[key]!.removeAt(0);
          }
        }
      }
      _timeIndex++;
    });
  }

  void _seedInitialData() {
    for (final b in widget.batteries) {
      _lastValues.putIfAbsent(b.id, () => {
        'SOC': 72 + _random.nextDouble() * 15,
        'Voltage': 46 + _random.nextDouble() * 3,
        'Current': 4 + _random.nextDouble() * 8,
      });
      for (final metric in ['SOC', 'Voltage', 'Current']) {
        final key = '${b.id}|$metric';
        chartData.putIfAbsent(key, () => []);
        for (var t = 0; t <= 6; t++) {
          chartData[key]!.add(FlSpot(t.toDouble(), _lastValues[b.id]![metric]!));
        }
      }
      _timeIndex = 7;
    }
  }

  List<String> get _batteryOptions {
    final id = _selectedEvId;
    if (id == null) return [];
    return widget.batteries
        .where((b) => b.id.startsWith('$id-'))
        .map((b) => b.id)
        .toList()
      ..sort();
  }

  void _startMockData() {
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || widget.mqttConnected) {
        timer.cancel();
        return;
      }
      setState(() {
        for (final b in widget.batteries) {
          _lastValues.putIfAbsent(b.id, () => {
            'SOC': 72 + _random.nextDouble() * 15,
            'Voltage': 46 + _random.nextDouble() * 3,
            'Current': 4 + _random.nextDouble() * 8,
          });
          final last = _lastValues[b.id]!;
          last['SOC'] = (last['SOC']! + (_random.nextDouble() - 0.5) * 3)
              .clamp(60, 95);
          last['Voltage'] = (last['Voltage']! + (_random.nextDouble() - 0.5) * 1.0)
              .clamp(44, 50);
          last['Current'] = (last['Current']! + (_random.nextDouble() - 0.5) * 4)
              .clamp(-5, 20);

          for (final metric in ['SOC', 'Voltage', 'Current']) {
            final key = '${b.id}|$metric';
            chartData.putIfAbsent(key, () => []);
            chartData[key]!.add(FlSpot(_timeIndex.toDouble(), last[metric]!));
            if (chartData[key]!.length > _maxPoints) {
              chartData[key]!.removeAt(0);
            }
          }
        }
        _timeIndex++;
      });
    });
  }

  final Map<String, Color> metricColors = {
    'SOC': const Color(0xFF4FC3F7),
    'Voltage': const Color(0xFFFFD54F),
    'Current': const Color(0xFFEF5350),
  };

  final Map<String, String> metricUnits = {
    'SOC': '%',
    'Voltage': 'V',
    'Current': 'A',
  };

  String? _selectedEvId;

  List<String> get _evIds =>
      widget.batteries.map((b) => b.id.split('-').first).toSet().toList()
        ..sort();

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      if (isStart) {
        _startDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startDate.hour,
          _startDate.minute,
        );
      } else {
        _endDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endDate.hour,
          _endDate.minute,
        );
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      if (isStart) {
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          picked.hour,
          picked.minute,
        );
      } else {
        _endDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          picked.hour,
          picked.minute,
        );
      }
    });
  }

  Future<void> _handleDownload() async {
    if (widget.onDownload == null) return;
    setState(() => _downloading = true);
    try {
      await widget.onDownload!(
        start: _startDate,
        end: _endDate,
        evid: _selectedEvId,
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _handleGo() async {
    if (widget.onGo == null || widget.mqttConnecting) return;
    await widget.onGo!(bms1: _bms1, bms2: _bms2);
  }

  void _toggleGraph() {
    setState(() {
      _showGraph = !_showGraph;
    });
    widget.onGraphVisibilityChanged?.call(_showGraph);
    if (_showGraph) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  List<LineChartBarData> get _visibleBars {
    if (selectedBatteryIds.isEmpty || selectedMetrics.isEmpty) return [];
    _barLabels.clear();
    final bars = <LineChartBarData>[];
    for (final batteryId in selectedBatteryIds) {
      for (final metric in selectedMetrics) {
        final key = '$batteryId|$metric';
        final spots = chartData[key] ?? [];
        if (spots.isEmpty) continue;
        _barLabels.add(_BarLabel(batteryId, metric));
        final color = _lineColor(batteryId, metric);
        bars.add(LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.05),
          ),
        ));
      }
    }
    return bars;
  }

  Color _lineColor(String batteryId, String metric) {
    final base = metricColors[metric]!;
    final batteryIndex = widget.batteries
        .indexWhere((b) => b.id == batteryId);
    final hsl = HSLColor.fromColor(base);
    return hsl.withHue((hsl.hue + batteryIndex * 60) % 360).toColor();
  }

  double get _chartMinX {
    final data = chartData.values.firstOrNull ?? [];
    if (data.length <= _windowSize) return 0;
    return data.first.x;
  }

  double get _chartMaxX {
    final data = chartData.values.firstOrNull ?? [];
    if (data.isEmpty) return _windowSize.toDouble();
    return max(data.last.x, _windowSize.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evIds = _evIds;
    if (_selectedEvId == null && evIds.isNotEmpty) {
      _selectedEvId = evIds.first;
      selectedBatteryIds = _batteryOptions;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _showGraph
              ? _graphView(theme)
              : _controlsView(theme),
        ),
      ),
    );
  }

  Widget _controlsView(ThemeData theme) {
    final evIds = _evIds;
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),

          // ── BMS config (published to data/config) ───────────────
          Text('BMS Configuration', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _bms1,
                  decoration: const InputDecoration(
                    labelText: 'BMS 1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: bmsOptions
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: widget.mqttConnected
                      ? null
                      : (v) => setState(() => _bms1 = v ?? _bms1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _bms2,
                  decoration: const InputDecoration(
                    labelText: 'BMS 2',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: bmsOptions
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: widget.mqttConnected
                      ? null
                      : (v) => setState(() => _bms2 = v ?? _bms2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Go: publish config + subscribe monitoring ───────────
          if (widget.mqttConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_rounded, color: scheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.statusMessage ?? 'Connected — receiving live data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.mqttConnecting ? null : _handleGo,
                icon: widget.mqttConnecting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(widget.mqttConnecting ? 'Connecting…' : 'Go'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          const SizedBox(height: 20),
          
          const SizedBox(height: 12),

          if (_batteryOptions.isNotEmpty)
            MultiSelectDialogField(
              items: _batteryOptions
                  .map((e) => MultiSelectItem<String>(e, e))
                  .toList(),
              title: const Text('Select Batteries'),
              buttonText: Text(
              selectedBatteryIds.isEmpty
                  ? 'Batteries'
                  : selectedBatteryIds.length == 1
                      ? '1 Battery'
                      : '${selectedBatteryIds.length} Batteries',
              ),
              initialValue: selectedBatteryIds,
              searchable: true,
              dialogHeight: 400,
              onConfirm: (values) {
                setState(() => selectedBatteryIds = values.cast<String>());
              },
            ),
          const SizedBox(height: 12),

          MultiSelectDialogField(
            items: metricOptions
                .map((e) => MultiSelectItem<String>(e, e))
                .toList(),
            title: const Text('Select Metrics'),
            buttonText: const Text('Metrics'),
            initialValue: selectedMetrics,
            searchable: false,
            dialogHeight: 350,
            onConfirm: (values) {
              setState(() => selectedMetrics = values.cast<String>());
            },
          ),
          const SizedBox(height: 12),

          if (selectedMetrics.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: selectedMetrics.map((metric) {
                final color = metricColors[metric]!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24, height: 3,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$metric (${metricUnits[metric]})',
                      style: TextStyle(
                        color: color, fontSize: 12, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          Center(
            child: FilledButton.icon(
              onPressed: _toggleGraph,
              icon: const Icon(Icons.show_chart_rounded),
              label: const Text('Show Graph in Landscape'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  Widget _graphView(ThemeData theme) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: _visibleBars.isEmpty
              ? Center(
                  child: Text(
                    selectedBatteryIds.isEmpty
                        ? 'Select at least one battery pack'
                        : selectedMetrics.isEmpty
                            ? 'Select at least one metric'
                            : 'No data yet',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : LineChart(
                  LineChartData(
                    minX: _chartMinX,
                    maxX: _chartMaxX,
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipMargin: 8,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final label = spot.barIndex < _barLabels.length
                              ? _barLabels[spot.barIndex]
                              : null;
                          final batteryId = label?.batteryId ?? '';
                          final metric = label?.metric ?? '';
                          final color =
                              metricColors[metric] ?? Colors.white;
                          return LineTooltipItem(
                            '$batteryId $metric: ${spot.y.toStringAsFixed(1)} ${metricUnits[metric] ?? ''}',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) => Text(
                            'T${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    lineBarsData: _visibleBars,
                  ),
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            onPressed: _toggleGraph,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close graph',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black26,
            ),
          ),
        ),
      ],
    );
  }

}
