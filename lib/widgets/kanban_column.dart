import 'package:flutter/material.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/kanban_column_data.dart';
import 'package:quiz/widgets/my_task_list.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.label,
    required this.controller,
  });

  final String status;
  final String label;
  final KanbanController controller;

  Color get _headerColor {
    switch (status) {
      case 'todo':
        return Colors.orange.shade600;
      case 'inProgress':
        return Colors.blue.shade600;
      case 'done':
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasksFor(status);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _headerColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (tasks.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No tasks',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                  ),
                ),
              )
            else
              MyTaskList(
                columnData: KanbanColumnData(label: label, tasks: tasks),
                onDelete: (i) => controller.deleteTask(tasks[i]),
              ),
          ],
        ),
      ),
    );
  }
}
