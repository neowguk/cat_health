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
  final String controlTopic = 'cat_tower/control';

  late MqttServerClient client;
  StreamSubscription? _updatesSub;
  bool _subscribed = false;

  double weight = 0.0;
  bool heater = false;
  String connectionStatus = 'disconnected';

  String lastStatusTopic = '';
  String lastStatusMessage = '';
  String lastRfid = '';
  String lastCatName = '';
  DateTime? lastUpdated;

  bool ignoreHeater = false;

  Function(String uid)? onNewTag;

  Future<void> connect() async {
    if (connectionStatus == 'connecting') return;

    client = MqttServerClient(broker, 'flutter_cathealth_client');
    client.port = port;
    client.secure = true;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.setProtocolV311();
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = false;

    final connMess = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier('flutter_cathealth_client');

    client.connectionMessage = connMess;

    try {
      connectionStatus = 'connecting';
      notifyListeners();

      await _updatesSub?.cancel();
      _updatesSub = null;
      _subscribed = false;

      await client.connect();

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        connectionStatus = 'connected';
        _subscribeTopicsIfNeeded();
        _listenUpdates();
        notifyListeners();
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

  void _subscribeTopicsIfNeeded() {
    if (_subscribed) return;
    client.subscribe(stateTopic, MqttQos.atMostOnce);
    client.subscribe(statusTopic, MqttQos.atLeastOnce);
    _subscribed = true;
  }

  void _listenUpdates() {
    _updatesSub ??=
        client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final message = events[0];
      final topic = message.topic;
      final recMess = message.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (topic == stateTopic) {
        final data = jsonDecode(payload);

        if (!ignoreHeater) {
          weight = ((data['weight'] ?? 0) as num).toDouble();
          heater = data['heater'] ?? false;
        }

        lastUpdated = DateTime.now();
      } else if (topic == statusTopic) {
        lastStatusTopic = topic;
        lastStatusMessage = payload;
        lastUpdated = DateTime.now();

        try {
          final data = jsonDecode(payload);
          lastRfid = data['rfid']?.toString() ?? data['uid']?.toString() ?? '';
          lastCatName =
              data['catName']?.toString() ?? data['name']?.toString() ?? '';
        } catch (_) {}

        if (lastRfid.isNotEmpty) {
          onNewTag?.call(lastRfid);
        }
      }

      notifyListeners();
    });
  }

  void resetLiveState() {
    weight = 0.0;
    heater = false;
    lastStatusTopic = '';
    lastStatusMessage = '';
    lastRfid = '';
    lastCatName = '';
    lastUpdated = null;
    ignoreHeater = false;
    notifyListeners();
  }

  Future<void> setHeater(bool value) async {
    heater = value;
    ignoreHeater = false;
    notifyListeners();

    if (connectionStatus != 'connected') return;

    final payload = jsonEncode({
      'heater': value,
      'source': 'app',
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    client.publishMessage(
      controlTopic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  Future<void> toggleHeater() async {
    await setHeater(!heater);
  }

  void _onConnected() {
    connectionStatus = 'connected';
    _subscribeTopicsIfNeeded();
    _listenUpdates();
    notifyListeners();
  }

  void _onDisconnected() {
    connectionStatus = 'disconnected';
    _subscribed = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {}

  @override
  void dispose() {
    _updatesSub?.cancel();
    client.disconnect();
    super.dispose();
  }
}
