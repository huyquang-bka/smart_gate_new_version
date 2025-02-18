import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';
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
      await _mqttSubscription?.cancel();
      _mqttSubscription = mqttService.client.updates?.listen(
        (List<MqttReceivedMessage<MqttMessage>> messages) {
          for (var message in messages) {
            final recMess = message.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
                recMess.payload.message);
            try {
              final data = json.decode(payload);
              // Handle cargo type message
              if (message.topic == AppConstants.mqttTopicCargoType) {
                _handleCargoTypeMessage(data);
                continue;
              }

              // Handle container message (existing logic)
              if ((data['ContainerCode1']?.toString().isNotEmpty ?? false) ||
                  (data['ContainerCode2']?.toString().isNotEmpty ?? false)) {
                _handleContainerMessage(data);
              }
            } catch (e) {
              debugPrint('Error parsing MQTT message: $e');
            }
          }
        },
      );

      // Subscribe to cargo type topic
      mqttService.client
          .subscribe(AppConstants.mqttTopicCargoType, MqttQos.atLeastOnce);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing MQTT in provider: $e');
      _isInitialized = false;
    }
  }

  void _handleCargoTypeMessage(Map<String, dynamic> data) {
    final checkPointId = data['checkPointId'] as int?;
    if (checkPointId == null) return;

    // Only update if cargo types are null or in default list
    final shouldUpdateCargoType1 =
        AppConstants.defaultCargoTypeCode.contains(data['cargoType1']);
    final shouldUpdateCargoType2 =
        AppConstants.defaultCargoTypeCode.contains(data['cargoType2']);
    if (!shouldUpdateCargoType1 && !shouldUpdateCargoType2) {
      return;
    }
    final existingIndex =
        _tasks.indexWhere((t) => t.checkPointId == checkPointId);
    if (existingIndex != -1) {
      final task = _tasks[existingIndex];

      _tasks[existingIndex] = task.copyWith(
        cargoType1: shouldUpdateCargoType1
            ? data['cargoType1'] as String?
            : task.cargoType1,
        cargoType2: shouldUpdateCargoType2
            ? data['cargoType2'] as String?
            : task.cargoType2,
      );
      notifyListeners();
    }
  }

  void _handleContainerMessage(Map<String, dynamic> data) async {
    try {
      final selectedCheckpointIds =
          await CheckpointService.getSelectedCheckpointIds();
      final task = Task.fromJson(data);
      if (selectedCheckpointIds.contains(task.checkPointId.toString())) {
        final existingIndex =
            _tasks.indexWhere((t) => t.checkPointId == task.checkPointId);

        if (existingIndex != -1) {
          if (task.timeInOut.isAfter(_tasks[existingIndex].timeInOut)) {
            _tasks[existingIndex] = task;
            notifyListeners();
          }
        } else {
          _tasks.insert(0, task);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Invalid container data: $e');
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
