import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/bms_telemetry.dart';

class MqttService {
  MqttServerClient? _client;
  final _telemetryController = StreamController<BmsTelemetry>.broadcast();

  bool _isConnected = false;
  bool _intentionalDisconnect = false;

  String host;
  int port;

  MqttService({
    this.host = 'localhost',
    this.port = 1883,
  });

  Stream<BmsTelemetry> get telemetryStream => _telemetryController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    _intentionalDisconnect = false;
    final id = 'battery_monitor_${Random().nextInt(99999)}';
    _client = MqttServerClient(host, id);
    _client!.port = port;
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;
    _client!.onAutoReconnect = () {};
    _client!.onAutoReconnected = () {};

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(id);
    _client!.connectionMessage = connMessage;

    _client!.onConnected = () {
      _isConnected = true;
    };

    _client!.onDisconnected = () {
      _isConnected = false;
      if (!_intentionalDisconnect) {}
    };

    try {
      await _client!.connect();
    } catch (e) {
      _isConnected = false;
      return;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      _isConnected = true;
      _client!.subscribe('ev/bms/+/telemetry', MqttQos.atLeastOnce);
      _client!.updates!.listen(_onMessage);
    }
  }

  void _onMessage(List<MqttReceivedMessage> messages) {
    for (final msg in messages) {
      final payload = msg.payload as MqttPublishMessage;
      final bytes = payload.payload.message;
      final text = String.fromCharCodes(bytes);

      try {
        final json = jsonDecode(text) as Map<String, dynamic>;
        final telemetry = BmsTelemetry.fromJson(json);
        _telemetryController.add(telemetry);
      } catch (_) {}
    }
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _isConnected = false;
    _client?.disconnect();
    _client = null;
  }

  void dispose() {
    disconnect();
    _telemetryController.close();
  }
}
