import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';

typedef MqttConnectionCallback = void Function(bool isConnected);

class MqttService {
  late MqttServerClient client;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  // Add connection status stream controller
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  MqttService() {
    _initializeClient();
  }

  void _initializeClient() {
    final clientId = DateTime.now().millisecondsSinceEpoch.toString();
    client = MqttServerClient(AppConstants.mqttBroker, clientId);
    client.port = AppConstants.mqttPort;
    client.keepAlivePeriod = 30;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
  }

  Future<void> connect() async {
    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect(
          AppConstants.mqttUsername, AppConstants.mqttPassword);
    } on Exception catch (e) {
      print('EXCEPTION: $e');
      client.disconnect();
      _startReconnectTimer();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint(
          'Connected to ${AppConstants.mqttBroker}:${AppConstants.mqttPort} as ${client.clientIdentifier}');
      _isConnected = true;
      _stopReconnectTimer();
    } else {
      print(
          'Connection failed - disconnecting client ${client.clientIdentifier} from broker ${AppConstants.mqttBroker} on port ${AppConstants.mqttPort}');
      client.disconnect();
      _startReconnectTimer();
    }
  }

  void _onConnected() {
    print('Connected');
    _isConnected = true;
    _connectionController.add(true);
    
    // Subscribe to all required topics
    final topics = [
      AppConstants.mqttTopicEvent,
      AppConstants.mqttTopicCargoType,
      AppConstants.mqttTopicCheckSeal,
    ];

    for (var topic in topics) {
      client.subscribe(topic, MqttQos.atLeastOnce);
    }
    
    _stopReconnectTimer();
  }

  void _onDisconnected() {
    print('Disconnected');
    _isConnected = false;
    _connectionController.add(false);
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
        _initializeClient();
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
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _stopReconnectTimer();
    _isConnected = false;
    client.disconnect();
  }

  void dispose() {
    disconnect();
    _connectionController.close();
  }
}

final mqttService = MqttService();
