import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';
import 'package:smart_gate_new_version/core/services/checkpoint_service.dart';
import 'package:smart_gate_new_version/features/task/domain/models/task.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _mqttSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isInitialized = false;

  List<Task> get tasks => _tasks;

  TaskProvider() {
    _setupMqttConnection();
  }

  void _setupMqttConnection() {
    _connectionSubscription =
        mqttService.connectionStream.listen((isConnected) {
      debugPrint(
          'MQTT Connection Status: ${isConnected ? 'Connected' : 'Disconnected'}');
      if (isConnected) {
        _initializeMqtt();
      } else {
        _isInitialized = false;
        _mqttSubscription?.cancel();
      }
    });

    _initializeMqtt();
  }

  Future<void> _initializeMqtt() async {
    if (_isInitialized) return;

    try {
      final selectedCheckpointIds =
          await CheckpointService.getSelectedCheckpointIds();

      await _mqttSubscription?.cancel();

      _mqttSubscription = mqttService.client.updates?.listen(
        (List<MqttReceivedMessage<MqttMessage>> messages) {
          for (var message in messages) {
            final recMess = message.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
                recMess.payload.message);
            try {
              final data = json.decode(payload);
              if (data['ContainerCode1'] != null ||
                  data['ContainerCode2'] != null) {
                try {
                  final task = Task.fromJson(data);
                  if (selectedCheckpointIds
                          .contains(task.checkPointId.toString()) &&
                      !_tasks.any((t) => t.eventId == task.eventId)) {
                    _tasks.insert(0, task);
                    notifyListeners();
                  }
                } catch (e) {
                  debugPrint('Invalid container data: $e');
                }
              }
            } catch (e) {
              debugPrint('Error parsing MQTT message: $e');
            }
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing MQTT in provider: $e');
      _isInitialized = false;
    }
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    notifyListeners();
  }

  void markTaskAsCompleted(Task task) {
    final index = _tasks.indexWhere((t) => t.eventId == task.eventId);
    if (index != -1) {
      _tasks[index] = task.copyWith(isCompleted: true);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
