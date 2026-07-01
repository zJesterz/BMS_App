import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../models/battery.dart';
import '../services/auth_service.dart';
import '../services/battery_service.dart';
import '../services/ev_service.dart';
import '../widgets/battery_gauge_card.dart';

class BatteriesPage extends StatefulWidget {
  const BatteriesPage({
    super.key,
    required this.batteryService,
    required this.authService,
    required this.onRefresh,
    this.mqttConnected = false,
    this.mqttConnecting = false,
    this.batteryUpdateTick = 0,
    this.onGo,
    this.statusMessage,
  });

  final BatteryService batteryService;
  final AuthService authService;
  final Future<void> Function() onRefresh;
  final bool mqttConnected;
  final bool mqttConnecting;
  final int batteryUpdateTick;
  final Future<void> Function({
    required String bms1,
    required String bms2,
  })? onGo;
  final String? statusMessage;

  @override
  State<BatteriesPage> createState() => _BatteriesPageState();
}

class _BatteriesPageState extends State<BatteriesPage> {
  List<EvConfig> _evConfigs = [];
  String? _selectedEvId;
  List<String> _selectedBatteryIds = [];
  List<Battery> _batteries = [];
  bool _loading = true;

  final List<String> bmsOptions = ['Daly', 'Jiabaida'];
  String _bms1 = 'Daly';
  String _bms2 = 'Daly';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(BatteriesPage old) {
    super.didUpdateWidget(old);
    if (old.batteryUpdateTick != widget.batteryUpdateTick ||
        (old.mqttConnected != widget.mqttConnected && widget.mqttConnected)) {
      _loadBatteries(showLoading: false);
    }
  }

  Future<void> _init() async {
    final email = widget.authService.currentUserEmail;
    if (email != null) {
      try {
        final evs = await EvService().getEvsForUser(email);
        _evConfigs = evs;
        if (evs.isNotEmpty) _selectedEvId = evs.first.evid;
      } catch (_) {}
    }
    await _loadBatteries();
  }

  Future<void> _loadBatteries({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final all = await widget.batteryService.fetchBatteries();

    if (_evConfigs.isEmpty && all.isNotEmpty) {
      final evIds =
          all
              .map((b) => b.id.contains('-') ? b.id.split('-').first : b.id)
              .toSet()
              .toList()
            ..sort();
      _evConfigs =
          evIds
              .map(
                (id) => EvConfig(
                  evid: id,
                  mqttClient: '',
                  mqttUsername: '',
                  mqttPassword: '',
                  iotEndpoint: '',
                ),
              )
              .toList();
      _selectedEvId ??= _evConfigs.first.evid;
    }

    setState(() {
      _batteries = all;
      _loading = false;
      if (widget.mqttConnected && _selectedBatteryIds.isEmpty) {
        final evPacks = _evBatteries;
        if (evPacks.isNotEmpty) {
          _selectedBatteryIds = evPacks.map((b) => b.id).toList();
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    await widget.onRefresh();
    await _loadBatteries();
  }

  Future<void> _handleGo() async {
    if (widget.onGo == null || widget.mqttConnecting) return;
    await widget.onGo!(bms1: _bms1, bms2: _bms2);
  }

  List<Battery> get _evBatteries {
    final evId = _selectedEvId;
    if (evId == null) return [];
    return _batteries
        .where((b) => b.id.startsWith('$evId-') || b.id == evId)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  List<Battery> get _selectedBatteries {
    if (_selectedBatteryIds.isEmpty) return [];
    return _batteries.where((b) => _selectedBatteryIds.contains(b.id)).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final evBatteries = _evBatteries;
    final displayBatteries =
        widget.mqttConnected && _selectedBatteryIds.isEmpty
            ? evBatteries
            : _selectedBatteries;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final hPad = isWide ? 32.0 : 16.0;
          final maxWidth = isWide ? 1100.0 : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
                children: [
                  // ── Header ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Telemetry',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live battery pack telemetry',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── EV selector ────────────────────────────────────
                  if (_evConfigs.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEvId,
                      decoration: InputDecoration(
                        labelText: 'Select EV',
                        prefixIcon: const Icon(Icons.electric_car_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items:
                          _evConfigs.map((ev) {
                            return DropdownMenuItem(
                              value: ev.evid,
                              child: Text(ev.evid),
                            );
                          }).toList(),
                      onChanged:
                          widget.mqttConnected
                              ? null
                              : (id) => setState(() {
                                    _selectedEvId = id;
                                    _selectedBatteryIds = [];
                                  }),
                    ),

                  const SizedBox(height: 12),

                  // ── Battery pack multi-select ──────────────────────
                  if (evBatteries.isNotEmpty)
                   MultiSelectDialogField<String>(
                    items: evBatteries
                        .map((b) => MultiSelectItem<String>(b.id, b.name))
                        .toList(),
                    title: Text(
                      'Select Battery Packs',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                    buttonText: Text(
                      'Choose Battery Packs',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                    itemsTextStyle: TextStyle(color: scheme.onSurface),
                    selectedItemsTextStyle: TextStyle(color: scheme.primary),
                    unselectedColor: scheme.onSurfaceVariant,
                    selectedColor: scheme.primary,
                    checkColor: scheme.onPrimary,
                    backgroundColor: scheme.surfaceContainerHigh,
                    cancelText: Text('Cancel', style: TextStyle(color: scheme.onSurfaceVariant)),
                    confirmText: Text('OK', style: TextStyle(color: scheme.primary)),
                    initialValue: _selectedBatteryIds,
                    searchable: false,
                    dialogHeight: 400,
                    chipDisplay: MultiSelectChipDisplay<String>(
                      items: _selectedBatteryIds
                          .map((id) => MultiSelectItem<String>(
                                id,
                                evBatteries
                                    .firstWhere((b) => b.id == id)
                                    .name,
                              ))
                          .toList(),
                      textStyle: TextStyle(color: scheme.onSurface),
                      chipColor: scheme.surfaceContainerHigh,
                      onTap: (value) {
                        setState(() => _selectedBatteryIds.remove(value));
                      },
                    ),
                    onConfirm: (values) {
                      setState(() => _selectedBatteryIds = values);
                    },
                   ),


                   // ── Connection status / Go button ──────────────────
                  if (widget.mqttConnected)
                    _StatusBanner(
                      icon: Icons.wifi_rounded,
                      label: 'Connected — receiving live data',
                      color: scheme.primary,
                    )
                  else if (widget.mqttConnecting)
                    _StatusBanner(
                      icon: Icons.sync_rounded,
                      label: 'Connecting to MQTT broker…',
                      color: scheme.tertiary,
                      showSpinner: true,
                    )
                  else ...[
                    // BMS type selectors
                    Text(
                      'BMS Configuration',
                      style: theme.textTheme.titleSmall,
                    ),
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
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _bms1 = v ?? _bms1),
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
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _bms2 = v ?? _bms2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _handleGo,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Go'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (widget.statusMessage != null) ...[
                      const SizedBox(height: 12),
                      _StatusBanner(
                        icon: Icons.error_outline_rounded,
                        label: widget.statusMessage!,
                        color: scheme.error,
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  // ── Battery gauges ─────────────────────────────────
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (evBatteries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.battery_unknown_rounded,
                              size: 48,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedEvId == null
                                  ? 'No EV selected'
                                  : 'No battery data for $_selectedEvId',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (displayBatteries.isNotEmpty)
                    ...displayBatteries.map(
                      (battery) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RepaintBoundary(
                          key: ValueKey('${battery.id}_rb'),
                          child: BatteryGaugeCard(
                            key: ValueKey(battery.id),
                            battery: battery,
                            onTap: null,
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Text(
                          'Select battery packs above',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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

// ── Status banner ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.label,
    required this.color,
    this.showSpinner = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (showSpinner)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
