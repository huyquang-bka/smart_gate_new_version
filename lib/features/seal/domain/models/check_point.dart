import 'package:flutter/foundation.dart';

@immutable
class CheckPoint {
  final int id;
  final String code;
  final int compId;
  final String? compName;
  final String? devicesId;
  final String? devicesName;
  final String name;
  final int? portLocation;
  final String? portLocationStr;
  final String? note;
  final bool? status;
  final String? statusStr;
  final bool? isDelete;
  final String? hiddenParentField;
  final int? laneId;
  final String? lanename;

  const CheckPoint({
    required this.id,
    required this.code,
    required this.compId,
    required this.name,
    this.compName,
    this.devicesId,
    this.devicesName,
    this.portLocation,
    this.portLocationStr,
    this.note,
    this.status,
    this.statusStr,
    this.isDelete,
    this.hiddenParentField,
    this.laneId,
    this.lanename,
  });

  factory CheckPoint.fromJson(Map<String, dynamic> json) => CheckPoint(
        id: json['id'] as int,
        code: json['code'] as String,
        compId: json['compId'] as int,
        name: json['name'] as String,
        compName: json['compName'] as String?,
        devicesId: json['devicesId'] as String?,
        devicesName: json['devicesName'] as String?,
        portLocation: json['portLocation'] as int?,
        portLocationStr: json['portLocationStr'] as String?,
        note: json['note'] as String?,
        status: json['status'] as bool?,
        statusStr: json['statusStr'] as String?,
        isDelete: json['isDelete'] as bool?,
        hiddenParentField: json['hiddenParentField'] as String?,
        laneId: json['laneId'] as int?,
        lanename: json['lanename'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'compId': compId,
        'name': name,
        if (compName != null) 'compName': compName,
        if (devicesId != null) 'devicesId': devicesId,
        if (devicesName != null) 'devicesName': devicesName,
        if (portLocation != null) 'portLocation': portLocation,
        if (portLocationStr != null) 'portLocationStr': portLocationStr,
        if (note != null) 'note': note,
        if (status != null) 'status': status,
        if (statusStr != null) 'statusStr': statusStr,
        if (isDelete != null) 'isDelete': isDelete,
        if (hiddenParentField != null) 'hiddenParentField': hiddenParentField,
        if (laneId != null) 'laneId': laneId,
        if (lanename != null) 'lanename': lanename,
      };

  CheckPoint copyWith({
    int? id,
    String? code,
    int? compId,
    String? name,
    String? compName,
    String? devicesId,
    String? devicesName,
    int? portLocation,
    String? portLocationStr,
    String? note,
    bool? status,
    String? statusStr,
    bool? isDelete,
    String? hiddenParentField,
    int? laneId,
    String? lanename,
  }) =>
      CheckPoint(
        id: id ?? this.id,
        code: code ?? this.code,
        compId: compId ?? this.compId,
        name: name ?? this.name,
        compName: compName ?? this.compName,
        devicesId: devicesId ?? this.devicesId,
        devicesName: devicesName ?? this.devicesName,
        portLocation: portLocation ?? this.portLocation,
        portLocationStr: portLocationStr ?? this.portLocationStr,
        note: note ?? this.note,
        status: status ?? this.status,
        statusStr: statusStr ?? this.statusStr,
        isDelete: isDelete ?? this.isDelete,
        hiddenParentField: hiddenParentField ?? this.hiddenParentField,
        laneId: laneId ?? this.laneId,
        lanename: lanename ?? this.lanename,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckPoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          compId == other.compId &&
          name == other.name;

  @override
  int get hashCode =>
      id.hashCode ^ code.hashCode ^ compId.hashCode ^ name.hashCode;

  @override
  String toString() =>
      'CheckPoint(id: $id, code: $code, compId: $compId, name: $name)';
}
