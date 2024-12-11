import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:smart_gate_new_version/features/seal/domain/models/check_point.dart';

class CheckpointService {
  static const String _selectedCheckpointsKey = 'selected_checkpoints';
  static const String _allCheckpointsKey = 'all_checkpoints';

  static Future<void> saveAllCheckpoints(List<CheckPoint> checkpoints) async {
    final prefs = await SharedPreferences.getInstance();
    final checkpointMap = checkpoints
        .map((cp) => {
              'id': cp.id.toString(),
              'name': cp.name,
              'code': cp.code,
              'laneName': cp.lanename ?? '',
              'compId': cp.compId,
            })
        .toList();
    await prefs.setString(_allCheckpointsKey, jsonEncode(checkpointMap));
  }

  static Future<List<CheckPoint>> getAllCheckpoints() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_allCheckpointsKey);
    if (data == null) return [];

    final List<dynamic> checkpoints = jsonDecode(data);
    return checkpoints
        .map((cp) => CheckPoint(
              id: int.parse(cp['id']),
              name: cp['name'],
              code: cp['code'],
              lanename: cp['laneName'],
              compId: cp['compId'],
            ))
        .toList();
  }

  static Future<List<String>> getSelectedCheckpointIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedCheckpointsKey) ?? [];
  }

  static Future<void> saveSelectedCheckpointIds(
      List<String> checkpointIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedCheckpointsKey, checkpointIds);
  }

  static Future<List<CheckPoint>> getSelectedCheckpoints() async {
    final selectedIds = await getSelectedCheckpointIds();
    final allCheckpoints = await getAllCheckpoints();
    print("getSelectedCheckpoints: $selectedIds");
    print("getAllCheckpoints: ${allCheckpoints.length}");
    return allCheckpoints
        .where((cp) => selectedIds.contains(cp.id.toString()))
        .toList();
  }
}
