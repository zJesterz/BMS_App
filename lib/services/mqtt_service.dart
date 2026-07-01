import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../config/mqtt_config.dart';
import '../models/monitoring_payload.dart';

class MqttService {
  MqttServerClient? _client;

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;

  final StreamController<MonitoringPayload> _monitoringController =
      StreamController<MonitoringPayload>.broadcast();

  bool _isConnected = false;

  final String host;
  final int port;

  MqttService({
    this.host = MqttConfig.host,
    this.port = MqttConfig.port,
  });

  Stream<MonitoringPayload> get monitoringStream =>
      _monitoringController.stream;

  bool get isConnected => _isConnected;

  /// -------------------------------
  /// Publish BMS Configuration
  /// -------------------------------
  static Future<bool> publishBmsConfig({
    required String bms1,
    required String bms2,
    String host = MqttConfig.host,
    int port = MqttConfig.port,
    String username = MqttConfig.username,
    String password = MqttConfig.password,
  }) async {
    final clientId =
        'config_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final client = MqttServerClient.withPort(host, clientId, port);

    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 5000;
    client.logging(on: true);
    client.setProtocolV311();

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .startClean();

    try {
      print("Publishing config...");

      await client.connect();

      if (client.connectionStatus?.state !=
          MqttConnectionState.connected) {
        print("Failed to connect.");
        return false;
      }

      final payload = jsonEncode({
        "BMS1": bms1,
        "BMS2": bms2,
      });

      final builder = MqttClientPayloadBuilder()
        ..addString(payload);

      client.publishMessage(
        MqttConfig.configTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );

      print("Published:");
      print(payload);

      await Future.delayed(const Duration(seconds: 1));

      client.disconnect();

      return true;
    } catch (e) {
      print("Publish Error: $e");

      try {
        client.disconnect();
      } catch (_) {}

      return false;
    }
  }

  /// -------------------------------
  /// Connect for Live Monitoring
  /// -------------------------------
  Future<bool> connectMonitoring({
    String username = MqttConfig.username,
    String password = MqttConfig.password,
    String topic = MqttConfig.monitoringTopic,
  }) async {
    if (_isConnected) return true;

    disconnect();

    final clientId =
        'flutter_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    _client = MqttServerClient.withPort(
      host,
      clientId,
      port,
    );

    _client!
      ..logging(on: true)
      ..keepAlivePeriod = 30
      ..connectTimeoutPeriod = 5000
      ..autoReconnect = true
      ..setProtocolV311();

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.onConnected = () {
      _isConnected = true;
      print("MQTT Connected");
    };

    _client!.onDisconnected = () {
      _isConnected = false;
      print("MQTT Disconnected");
    };

    _client!.onAutoReconnect = () {
      print("Reconnecting...");
    };

    _client!.onAutoReconnected = () {
      print("Reconnected");

      _client!.subscribe(
        topic,
        MqttQos.atLeastOnce,
      );
    };

    _client!.pongCallback = () {
      print("Broker Alive");
    };

    try {
      print("Connecting to MQTT...");

      await _client!.connect();
    } catch (e) {
      print("Connection Error: $e");

      disconnect();

      return false;
    }

    if (_client!.connectionStatus?.state !=
        MqttConnectionState.connected) {
      print("Connection failed.");

      disconnect();

      return false;
    }

    print("Subscribing to $topic");

    _client!.subscribe(
      topic,
      MqttQos.atLeastOnce,
    );

    _updatesSub = _client!.updates!.listen(_onMessage);

    return true;
  }

  /// -------------------------------
  /// Incoming MQTT Messages
  /// -------------------------------
  void _onMessage(
    List<MqttReceivedMessage<MqttMessage>> messages,
  ) {
    for (final msg in messages) {
      if (msg.topic != MqttConfig.monitoringTopic) {
        continue;
      }

      final publishMessage =
          msg.payload as MqttPublishMessage;

      final text =
          MqttPublishPayload.bytesToStringAsString(
        publishMessage.payload.message,
      );

      print("================================");
      print("Topic   : ${msg.topic}");
      print("Payload : $text");
      print("================================");

      try {
        final json = jsonDecode(text);

        if (json is! Map<String, dynamic>) {
          print("Invalid JSON");
          continue;
        }

        final monitoring =
            MonitoringPayload.fromJson(json);

        _monitoringController.add(monitoring);
      } catch (e, stack) {
        print("JSON Error:");
        print(e);
        print(stack);
      }
    }
  }

  /// -------------------------------
  /// Disconnect
  /// -------------------------------
  void disconnect() {
    _isConnected = false;

    _updatesSub?.cancel();
    _updatesSub = null;

    _client?.disconnect();
    _client = null;
  }

  /// -------------------------------
  /// Dispose
  /// -------------------------------
  void dispose() {
    disconnect();

    if (!_monitoringController.isClosed) {
      _monitoringController.close();
    }
  }
}