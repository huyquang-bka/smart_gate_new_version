import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';
import 'package:smart_gate_new_version/core/services/checkpoint_service.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/check_point.dart';
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

              // Handle check seal message
              if (message.topic == AppConstants.mqttTopicCheckSeal) {
                _handleGateMessage(data);
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

      // Subscribe to all required topics
      mqttService.client
          .subscribe(AppConstants.mqttTopicCargoType, MqttQos.atLeastOnce);
      mqttService.client
          .subscribe(AppConstants.mqttTopicCheckSeal, MqttQos.atLeastOnce);

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
        AppConstants.defaultCargoTypeCode.contains(data['cargoType1']) ||
            data['seal1'] != null;
    final shouldUpdateCargoType2 =
        AppConstants.defaultCargoTypeCode.contains(data['cargoType2']) ||
            data['seal2'] != null;
    if (!shouldUpdateCargoType1 && !shouldUpdateCargoType2) {
      return;
    }
    final existingIndex =
        _tasks.indexWhere((t) => t.checkPointId == checkPointId);
    if (existingIndex != -1) {
      final task = _tasks[existingIndex];
      print("Message from cargo type: $data");
      _tasks[existingIndex] = task.copyWith(
        cargoType1: shouldUpdateCargoType1
            ? data['cargoType1'] as String?
            : task.cargoType1,
        cargoType2: shouldUpdateCargoType2
            ? data['cargoType2'] as String?
            : task.cargoType2,
        syncSeal1: data['seal1'] as String?,
        syncSeal2: data['seal2'] as String?,
      );
      print("Task after update cargo type: ${task.toJson()}");
      notifyListeners();
    }
  }

  void _handleGateMessage(Map<String, dynamic> data) async {
    try {
      print("ContainerGateMessage: $data");
      final selectedCheckpointIds =
          await CheckpointService.getSelectedCheckpointIds();
      final task = Task.fromJson({
        'EventId': data['EventId'] as String,
        'CheckPointId': data['CheckPointId'] as int,
        'ContainerCode1': data['ContainerCode1'] as String?,
        'ContainerCode2': data['ContainerCode2'] as String?,
        'TimeInOut': data['TimeInOut'] as String,
        'syncSeal1': data['Seal1'] as String?,
        'syncSeal2': data['Seal2'] as String?,
        'cargoType1': 'GP', // Default cargo type
        'cargoType2': 'GP', // Default cargo type
      });
      print("Task checkPointId: ${task.checkPointId}");
      print("Selected checkpoint ids: $selectedCheckpointIds");
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
      debugPrint('Invalid gate message data: $e');
    }
  }

  void _handleContainerMessage(Map<String, dynamic> data) async {
    try {
      final selectedCheckpointIds =
          await CheckpointService.getSelectedCheckpointIds();
      final task = Task.fromJson(data);
      final checkpoints = await CheckpointService.getAllCheckpoints();

      // Find the checkpoint for this task
      final checkpoint = checkpoints.firstWhere(
        (cp) => cp.id == task.checkPointId,
        orElse: () => const CheckPoint(
          id: -1,
          name: 'Unknown',
          code: '',
          compId: -1,
          portLocation: 0,
        ),
      );
      print("Checkpoint portLocation: ${checkpoint.portLocation}");
      // Skip task creation if portLocation is less than 3
      if (checkpoint.portLocation < 3) {
        return;
      }

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
