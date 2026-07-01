/// OpenIOE MQTT broker settings.
///
/// In production, prefer loading credentials from Firestore [EvConfig]
/// rather than hard-coding them here.
class MqttConfig {
  MqttConfig._();

  static const String host = 'mqtt.openioe.in';
  static const int port = 1883;
  static const String username = 'CQmGJZRH175gMHRudHR92mDR5';
  static const String password = 'lXOH762CaZvMm5Nfmfi9cCmAR';

  static const String configClientId = 'saEoggShe9N0ZfaCqHX3ba0jd_config';
  static const String mobileClientId = 'saEoggShe9N0ZfaCqHX3ba0jd_mobile';

  static const String configTopic = 'data/config';
  static const String monitoringTopic = 'data/monitoring';
}
