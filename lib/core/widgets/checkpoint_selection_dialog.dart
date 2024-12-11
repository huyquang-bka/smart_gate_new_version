import 'package:flutter/material.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/services/checkpoint_service.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/check_point.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CheckpointSelectionDialog extends StatefulWidget {
  final List<CheckPoint> checkpoints;
  final List<String> selectedIds;
  final bool isCollapsed;

  const CheckpointSelectionDialog({
    super.key,
    required this.checkpoints,
    required this.selectedIds,
    this.isCollapsed = true,
  });

  @override
  State<CheckpointSelectionDialog> createState() =>
      _CheckpointSelectionDialogState();
}

class _CheckpointSelectionDialogState extends State<CheckpointSelectionDialog> {
  late List<String> _selectedIds;
  late Map<String, bool> _groupExpanded;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds.where((id) => widget.checkpoints
        .any((checkpoint) => checkpoint.id.toString() == id)));
    _groupExpanded = {};
    _saveAllCheckpoints();
  }

  Future<void> _saveAllCheckpoints() async {
    await CheckpointService.saveAllCheckpoints(widget.checkpoints);
  }

  Map<String, List<CheckPoint>> _getGroupedCheckpoints() {
    final Map<String, List<CheckPoint>> grouped = {};
    for (var checkpoint in widget.checkpoints) {
      final String groupKey = checkpoint.lanename ?? '';
      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(checkpoint);
    }
    return grouped;
  }

  bool _isGroupSelected(List<CheckPoint> checkpoints) {
    return checkpoints.every((cp) => _selectedIds.contains(cp.id.toString()));
  }

  void _toggleGroup(List<CheckPoint> checkpoints, bool? value) {
    setState(() {
      for (var checkpoint in checkpoints) {
        if (value == true) {
          if (!_selectedIds.contains(checkpoint.id.toString())) {
            _selectedIds.add(checkpoint.id.toString());
          }
        } else {
          _selectedIds.remove(checkpoint.id.toString());
        }
      }
    });
  }

  Future<void> _saveSelectedCheckpoints() async {
    await CheckpointService.saveSelectedCheckpointIds(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupedCheckpoints = _getGroupedCheckpoints();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.selectCheckpoint,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: groupedCheckpoints.length,
              itemBuilder: (context, index) {
                final groupKey = groupedCheckpoints.keys.elementAt(index);
                final checkpoints = groupedCheckpoints[groupKey]!;
                final isExpanded =
                    _groupExpanded[groupKey] ?? !widget.isCollapsed;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _toggleGroup(
                            checkpoints, !_isGroupSelected(checkpoints)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Checkbox(
                              value: _isGroupSelected(checkpoints),
                              onChanged: (value) =>
                                  _toggleGroup(checkpoints, value),
                            ),
                            title: Text(
                              groupKey,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _groupExpanded[groupKey] = !isExpanded;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: checkpoints.map((checkpoint) {
                              final isSelected = _selectedIds
                                  .contains(checkpoint.id.toString());
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds
                                          .remove(checkpoint.id.toString());
                                    } else {
                                      _selectedIds
                                          .add(checkpoint.id.toString());
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      left: 24, bottom: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedIds
                                                .add(checkpoint.id.toString());
                                          } else {
                                            _selectedIds.remove(
                                                checkpoint.id.toString());
                                          }
                                        });
                                      },
                                    ),
                                    title: Text(
                                      checkpoint.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      l10n.code(checkpoint.code),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _saveSelectedCheckpoints();
                    if (context.mounted) {
                      Navigator.pop(context, _selectedIds);
                    }
                  },
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
