/// OpenIOE MQTT broker settings.
///
/// In production, prefer loading credentials from Firestore [EvConfig]
/// rather than hard-coding them here.
class MqttConfig {
  MqttConfig._();

  /// Override at build time via --dart-define=MQTT_HOST=...
  static String get host =>
      const String.fromEnvironment('MQTT_HOST', defaultValue: 'mqtt.openioe.in');

  static const int port = 1883;

  /// Override at build time via --dart-define=MQTT_USERNAME=...
  static String get username =>
      const String.fromEnvironment('MQTT_USERNAME', defaultValue: 'CQmGJZRH175gMHRudHR92mDR5');

  /// Override at build time via --dart-define=MQTT_PASSWORD=...
  static String get password =>
      const String.fromEnvironment('MQTT_PASSWORD', defaultValue: 'lXOH762CaZvMm5Nfmfi9cCmAR');

  static const String configClientId = 'saEoggShe9N0ZfaCqHX3ba0jd_config';
  static const String mobileClientId = 'saEoggShe9N0ZfaCqHX3ba0jd_mobile';

  static const String configTopic = 'data/config';
  static const String monitoringTopic = 'data/monitoring';
}
