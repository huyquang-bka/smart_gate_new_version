import 'package:flutter/foundation.dart';

@immutable
class Task {
  final String eventId;
  final int checkPointId;
  final int compId;
  final String containerCode1;
  final String? containerCode2;
  final DateTime timeInOut;
  final bool isCompleted;

  const Task({
    required this.eventId,
    required this.checkPointId,
    required this.compId,
    required this.containerCode1,
    this.containerCode2,
    required this.timeInOut,
    this.isCompleted = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final containerCode1 = json['ContainerCode1'] as String?;
    final containerCode2 = json['ContainerCode2'] as String?;

    // Only create task if at least one container code exists
    if (containerCode1 == null || containerCode1.isEmpty) {
      throw Exception('No valid container code');
    }

    return Task(
      eventId: json['EventId'] as String,
      checkPointId: json['CheckPointId'] as int,
      compId: json['CompId'] as int,
      containerCode1: containerCode1,
      containerCode2:
          containerCode2?.isNotEmpty == true ? containerCode2 : null,
      timeInOut: DateTime.parse(json['TimeInOut'] as String),
      isCompleted: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EventId': eventId,
      'CheckPointId': checkPointId,
      'CompId': compId,
      'ContainerCode1': containerCode1,
      if (containerCode2 != null) 'ContainerCode2': containerCode2,
      'TimeInOut': timeInOut.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  Task copyWith({
    String? eventId,
    int? checkPointId,
    int? compId,
    String? containerCode1,
    String? containerCode2,
    DateTime? timeInOut,
    bool? isCompleted,
  }) {
    return Task(
      eventId: eventId ?? this.eventId,
      checkPointId: checkPointId ?? this.checkPointId,
      compId: compId ?? this.compId,
      containerCode1: containerCode1 ?? this.containerCode1,
      containerCode2: containerCode2 ?? this.containerCode2,
      timeInOut: timeInOut ?? this.timeInOut,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
