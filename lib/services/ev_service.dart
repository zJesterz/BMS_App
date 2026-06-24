import 'package:cloud_firestore/cloud_firestore.dart';

class EvConfig {
  final String evid;
  final String mqttClient;
  final String mqttUsername;
  final String mqttPassword;
  final String iotEndpoint;

  EvConfig({
    required this.evid,
    required this.mqttClient,
    required this.mqttUsername,
    required this.mqttPassword,
    required this.iotEndpoint,
  });

  factory EvConfig.fromMap(Map<String, dynamic> map) {
    return EvConfig(
      evid: map['evid'] ?? '',
      mqttClient: map['mqtt_client'] ?? '',
      mqttUsername: map['mqtt_username'] ?? '',
      mqttPassword: map['mqtt_password'] ?? '',
      iotEndpoint: map['iotendpoint'] ?? '',
    );
  }
}

class EvService {
  final _db = FirebaseFirestore.instance;

  Future<List<EvConfig>> getEvsForUser(String email) async {
    final snapshot = await _db
        .collection('evs')
        .where('useremail', isEqualTo: email)
        .get();

    return snapshot.docs
        .map((doc) => EvConfig.fromMap(doc.data()))
        .toList();
  }
}