import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class MQTTClient {
  final String broker;
  final int port;
  final String clientId;
  final String username;
  final String password;
  final String topic;
  final Function onConnected;
  final Function onDisconnected;

  late MqttServerClient client;

  MQTTClient({
    required this.broker,
    required this.port,
    required this.clientId,
    required this.username,
    required this.password,
    required this.topic,
    required this.onConnected,
    required this.onDisconnected,
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
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to $broker:$port as $clientId - subscribing to $topic');
    } else {
      print(
          'Connection failed - disconnecting client $clientId from broker $broker on port $port');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('Connected');
    client.subscribe(topic, MqttQos.atLeastOnce);
    onConnected();
  }

  void _onDisconnected() {
    print('Disconnected');
    onDisconnected();
  }

  void _onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    final messageEncode = jsonEncode(message);

    final builder = MqttClientPayloadBuilder();
    builder.addString(messageEncode);
    await client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    client.disconnect();
  }
}
