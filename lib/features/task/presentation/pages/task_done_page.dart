import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smart_gate_new_version/features/task/providers/task_provider.dart';
import 'package:smart_gate_new_version/features/task/domain/models/task.dart';

class TaskDonePage extends StatelessWidget {
  const TaskDonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final taskProvider = Provider.of<TaskProvider>(context);
    final completedTasks = taskProvider.tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasksDone),
        centerTitle: true,
      ),
      body: completedTasks.isEmpty
          ? Center(
              child: Text(l10n.noCompletedTasks),
            )
          : ListView.builder(
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];
                return _buildTaskCard(context, task);
              },
            ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Container 1: ${task.containerCode1}'),
            if (task.containerCode2 != null)
              Text('Container 2: ${task.containerCode2}'),
          ],
        ),
        subtitle: Text(
          _formatDateTime(task.timeInOut, l10n),
        ),
        trailing: const Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime, AppLocalizations l10n) {
    return l10n.dateTimeFormat(
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
      dateTime.second.toString().padLeft(2, '0'),
      dateTime.day.toString().padLeft(2, '0'),
      dateTime.month.toString().padLeft(2, '0'),
      dateTime.year.toString(),
    );
  }
} 