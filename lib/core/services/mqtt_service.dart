import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';

class MqttService {
  final String broker;
  final int port;
  final String clientId;
  final String username;
  final String password;
  final String topic;
  late MqttServerClient client;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  MqttService({
    required this.broker,
    required this.port,
    required this.clientId,
    required this.username,
    required this.password,
    required this.topic,
  });

  Future<void> connect() async {
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.keepAlivePeriod = 30;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect(username, password);
    } on Exception catch (e) {
      print('EXCEPTION: $e');
      client.disconnect();
      _startReconnectTimer();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to $broker:$port as $clientId - subscribing to $topic');
      _isConnected = true;
      _stopReconnectTimer();
    } else {
      print(
          'Connection failed - disconnecting client $clientId from broker $broker on port $port');
      client.disconnect();
      _startReconnectTimer();
    }
  }

  void _onConnected() {
    print('Connected');
    _isConnected = true;
    _stopReconnectTimer();
    // client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('Disconnected');
    _isConnected = false;
    _startReconnectTimer();
  }

  void _onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  void _startReconnectTimer() {
    _stopReconnectTimer();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isConnected) {
        print('Attempting to reconnect...');
        await connect();
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> sendMessage(String topic, Map<String, dynamic> message) async {
    if (!_isConnected) {
      throw Exception('MQTT client is not connected');
    }
    final messageEncode = jsonEncode(message);

    final builder = MqttClientPayloadBuilder();
    builder.addString(messageEncode);
    await client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _stopReconnectTimer();
    _isConnected = false;
    client.disconnect();
  }
}
