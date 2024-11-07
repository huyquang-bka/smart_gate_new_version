import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';

class MqttService {
  static const String _broker = '27.72.98.49';
  static const int _port = 58883;
  static const String _username = 'admin';
  static const String _password = 'admin';
  final String _clientId = DateTime.now().millisecondsSinceEpoch.toString();

  late MqttServerClient client;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  MqttService() {
    client = MqttServerClient(_broker, _clientId);
    client.port = _port;
    client.keepAlivePeriod = 30;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
  }

  Future<void> connect() async {
    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect(_username, _password);
    } on Exception catch (e) {
      print('EXCEPTION: $e');
      client.disconnect();
      _startReconnectTimer();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('Connected to $_broker:$_port as $_clientId');
      _isConnected = true;
      _stopReconnectTimer();
    } else {
      print(
          'Connection failed - disconnecting client $_clientId from broker $_broker on port $_port');
      client.disconnect();
      _startReconnectTimer();
    }
  }

  void _onConnected() {
    print('Connected');
    _isConnected = true;
    _stopReconnectTimer();
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

final mqttService = MqttService();
