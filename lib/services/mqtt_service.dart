import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService extends ChangeNotifier {
  final String broker = '48c3ba6414d7464383ec7f469b55003d.s1.eu.hivemq.cloud';
  final int port = 8883;
  final String username = 'tkagh6a7ab';
  final String password = 'Ghkdxowk45@';

  final String stateTopic = 'cat_tower/state';
  final String statusTopic = 'cat_tower/status';

  late MqttServerClient client;

  double weight = 0.0;
  bool heater = false;
  String connectionStatus = 'disconnected';

  String lastStatusTopic = '';
  String lastStatusMessage = '';
  String lastRfid = '';
  String lastCatName = '';

  // ← 추가: 새 RFID 태그 감지 시 실행할 콜백
  Function(String uid)? onNewTag;

  Future<void> connect() async {
    client = MqttServerClient(broker, 'flutter_cathealth_client');
    client.port = port;
    client.secure = true;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.setProtocolV311();

    final connMess = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier('flutter_cathealth_client')
        .startClean();

    client.connectionMessage = connMess;

    try {
      connectionStatus = 'connecting';
      notifyListeners();

      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        connectionStatus = 'connected';
        notifyListeners();

        // state 토픽은 QoS 0 (주기 체중값)
        client.subscribe(stateTopic, MqttQos.atMostOnce);
        // status 토픽은 QoS 1 (RFID 이벤트 — 유실 방지)
        client.subscribe(statusTopic, MqttQos.atLeastOnce);

        client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
          final message = events[0];
          final topic = message.topic;
          final recMess = message.payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          if (topic == stateTopic) {
            final data = jsonDecode(payload);
            weight = ((data['weight'] ?? 0) as num).toDouble();
            heater = data['heater'] ?? false;
          } else if (topic == statusTopic) {
            lastStatusTopic = topic;
            lastStatusMessage = payload;

            try {
              final data = jsonDecode(payload);
              // rfid / uid 둘 다 대응
              lastRfid =
                  data['rfid']?.toString() ?? data['uid']?.toString() ?? '';
              // catName / name 둘 다 대응
              lastCatName =
                  data['catName']?.toString() ?? data['name']?.toString() ?? '';
            } catch (_) {}

            // ← 추가: 새 태그 감지 시 콜백 호출
            if (lastRfid.isNotEmpty) {
              onNewTag?.call(lastRfid);
            }
          }

          notifyListeners();
        });
      } else {
        connectionStatus = 'failed';
        client.disconnect();
        notifyListeners();
      }
    } catch (e) {
      connectionStatus = 'error';
      client.disconnect();
      notifyListeners();
    }
  }

  void _onConnected() {
    connectionStatus = 'connected';
    notifyListeners();
  }

  void _onDisconnected() {
    connectionStatus = 'disconnected';
    notifyListeners();
  }

  void _onSubscribed(String topic) {}

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}
