import 'package:flutter/foundation.dart';

@immutable
class Task {
  final String eventId;
  final int checkPointId;
  final int compId;
  final String? containerCode1;
  final String? containerCode2;
  final DateTime timeInOut;
  final bool isCompleted;
  final String cargoType1;
  final String cargoType2;
  final String? syncSeal1;
  final String? syncSeal2;

  const Task({
    required this.eventId,
    required this.checkPointId,
    required this.compId,
    this.containerCode1,
    this.containerCode2,
    required this.timeInOut,
    this.isCompleted = false,
    String? cargoType1,
    String? cargoType2,
    String? syncSeal1,
    String? syncSeal2,
  })  : cargoType1 = cargoType1 ?? 'GP',
        cargoType2 = cargoType2 ?? 'GP',
        syncSeal1 = syncSeal1 ?? '',
        syncSeal2 = syncSeal2 ?? '';

  factory Task.fromJson(Map<String, dynamic> json) {
    final containerCode1 = json['ContainerCode1'] as String?;
    final containerCode2 = json['ContainerCode2'] as String?;

    // Only create task if at least one container code exists
    if ((containerCode1 == null || containerCode1.isEmpty) &&
        (containerCode2 == null || containerCode2.isEmpty)) {
      throw Exception('No valid container code');
    }

    return Task(
      eventId: json['EventId'] as String,
      checkPointId: json['CheckPointId'] as int,
      compId: (json['CompId'] as int?) ?? 0,
      containerCode1:
          containerCode1?.isNotEmpty == true ? containerCode1 : null,
      containerCode2:
          containerCode2?.isNotEmpty == true ? containerCode2 : null,
      timeInOut: DateTime.parse(json['TimeInOut'] as String),
      isCompleted: false,
      cargoType1: json['cargoType1'] as String? ?? 'GP',
      cargoType2: json['cargoType2'] as String? ?? 'GP',
      syncSeal1: json['syncSeal1'] as String? ?? '',
      syncSeal2: json['syncSeal2'] as String? ?? '',
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
      'cargoType1': cargoType1,
      'cargoType2': cargoType2,
      'syncSeal1': syncSeal1,
      'syncSeal2': syncSeal2,
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
    String? cargoType1,
    String? cargoType2,
    String? syncSeal1,
    String? syncSeal2,
  }) {
    return Task(
      eventId: eventId ?? this.eventId,
      checkPointId: checkPointId ?? this.checkPointId,
      compId: compId ?? this.compId,
      containerCode1: containerCode1 ?? this.containerCode1,
      containerCode2: containerCode2 ?? this.containerCode2,
      timeInOut: timeInOut ?? this.timeInOut,
      isCompleted: isCompleted ?? this.isCompleted,
      cargoType1: cargoType1 ?? this.cargoType1,
      cargoType2: cargoType2 ?? this.cargoType2,
      syncSeal1: syncSeal1 ?? this.syncSeal1,
      syncSeal2: syncSeal2 ?? this.syncSeal2,
    );
  }
}
