import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class CatStatus {
  final bool catDetected;
  final String catName;
  final double weight;
  final bool heating;

  CatStatus({
    required this.catDetected,
    required this.catName,
    required this.weight,
    required this.heating,
  });

  factory CatStatus.empty() => CatStatus(
        catDetected: false,
        catName: '',
        weight: 0,
        heating: false,
      );
}

class RegisteredCat {
  final String uid;
  final String name;

  RegisteredCat({required this.uid, required this.name});
}

class ArduinoService extends ChangeNotifier {
  static const String host =
      '48c3ba6414d7464383ec7f469b55003d.s1.eu.hivemq.cloud';
  static const int port = 8883;
  static const String username = 'smart_cat';
  static const String password = 'Cattower123!';

  late MqttServerClient _client;

  CatStatus _status = CatStatus.empty();
  final List<RegisteredCat> _cats = [];
  bool _connected = false;

  CatStatus get status => _status;
  List<RegisteredCat> get cats => _cats;
  bool get connected => _connected;

  Future<void> connect() async {
    _client = MqttServerClient.withPort(host, 'cat_app_flutter', port);
    _client.secure = true;
    _client.keepAlivePeriod = 60;
    _client.logging(on: false);

    final connMsg = MqttConnectMessage()
        .withClientIdentifier('cat_app_flutter')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMsg;

    try {
      await _client.connect();
      _connected = true;
      notifyListeners();
    } catch (e) {
      _connected = false;
      _client.disconnect();
      notifyListeners();
      return;
    }

    _client.subscribe('cat_tower/status', MqttQos.atLeastOnce);
    _client.subscribe('cat_tower/state', MqttQos.atLeastOnce);

    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var msg in messages) {
        final topic = msg.topic;
        final recMess = msg.payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        final data = jsonDecode(payload);

        if (topic == 'cat_tower/status') {
          final uid = data['uid'] as String;
          final weight = (data['weight'] as num).toDouble();
          final heater = data['heater'] as bool;

          final cat = _findCatByUid(uid);

          _status = CatStatus(
            catDetected: true,
            catName: cat?.name ?? uid,
            weight: weight,
            heating: heater,
          );

          notifyListeners();
        } else if (topic == 'cat_tower/state') {
          final weight = (data['weight'] as num).toDouble();
          final heater = data['heater'] as bool;

          _status = CatStatus(
            catDetected: _status.catDetected,
            catName: _status.catName,
            weight: weight,
            heating: heater,
          );

          notifyListeners();
        }
      }
    });
  }

  void disconnect() {
    _connected = false;
    _client.disconnect();
    notifyListeners();
  }

  void startPolling() {
    connect();
  }

  void stopPolling() {
    disconnect();
  }

  Future<void> fetchStatus() async {
    // MQTT는 push 방식이라 별도 polling 불필요
  }

  Future<String?> scanRfid() async {
    // MQTT 구조에서는 별도 HTTP scan API가 없으므로 일단 미사용
    return null;
  }

  Future<bool> registerCat(String uid, String name) async {
    final existingIndex = _cats.indexWhere((cat) => cat.uid == uid);

    if (existingIndex >= 0) {
      _cats[existingIndex] = RegisteredCat(uid: uid, name: name);
    } else {
      _cats.add(RegisteredCat(uid: uid, name: name));
    }

    notifyListeners();
    return true;
  }

  Future<void> fetchCats() async {
    // 현재는 앱 메모리에만 유지
  }

  void setIp(String ip) {
    // MQTT에서는 IP 직접 사용 안 함
  }

  RegisteredCat? _findCatByUid(String uid) {
    try {
      return _cats.firstWhere((cat) => cat.uid == uid);
    } catch (_) {
      return null;
    }
  }
}
