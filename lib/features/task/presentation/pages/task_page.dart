import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/check_point.dart';
import 'package:smart_gate_new_version/features/task/domain/models/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smart_gate_new_version/features/task/providers/task_provider.dart';
import 'package:smart_gate_new_version/features/task/widgets/seal_task.dart';
import 'package:smart_gate_new_version/core/services/checkpoint_service.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<CheckPoint> _checkpoints = [];

  @override
  void initState() {
    super.initState();
    _loadCheckpoints();
  }

  Future<void> _loadCheckpoints() async {
    final checkpoints = await CheckpointService.getSelectedCheckpoints();
    setState(() {
      _checkpoints = checkpoints;
    });
  }

  String _getCheckpointDisplay(String checkpointId) {
    final l10n = AppLocalizations.of(context)!;
    final checkpoint = _checkpoints.firstWhere(
      (cp) => cp.id.toString() == checkpointId,
      orElse: () => CheckPoint(
        id: -1,
        name: l10n.unknownCheckpoint,
        code: '',
        compId: -1,
      ),
    );

    return checkpoint.lanename != null && checkpoint.lanename!.isNotEmpty
        ? l10n.checkpointWithLane(checkpoint.name, checkpoint.lanename!)
        : checkpoint.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final tasks = provider.tasks
            .where(
                (task) => _checkpoints.any((cp) => cp.id == task.checkPointId))
            .toList();
        final sortedTasks = List<Task>.from(tasks)
          ..sort((a, b) => a.timeInOut.compareTo(b.timeInOut));

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tasks),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: sortedTasks.isEmpty
              ? Center(child: Text(l10n.noTasks))
              : SingleChildScrollView(
                  child: Column(
                    children: sortedTasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SealTask(
                                  task: task,
                                  onTaskFinish: () {
                                    provider.removeTask(task);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildContainerInfo(l10n.container1Label,
                                      task.containerCode1),
                                  _buildContainerInfo(l10n.container2Label,
                                      task.containerCode2 ?? "?"),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoText(l10n.timeLabel,
                                          _formatDateTime(task.timeInOut)),
                                      const SizedBox(height: 4),
                                      _buildInfoText(
                                        l10n.checkpointLabel,
                                        _getCheckpointDisplay(
                                            task.checkPointId.toString()),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              provider.removeTask(task),
                                          icon: const Icon(Icons.delete,
                                              size: 18),
                                          label: Text(l10n.remove),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildContainerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, String value, {TextStyle? style}) {
    return RichText(
      text: TextSpan(
        style: style ?? const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(
              text: '$label: ', style: const TextStyle(color: Colors.black)),
          TextSpan(
              text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')} ${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}
