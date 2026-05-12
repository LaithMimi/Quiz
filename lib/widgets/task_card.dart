import 'package:flutter/material.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.controller});

  final Task task;
  final KanbanController controller;

  @override
  Widget build(BuildContext context) {
    final isFirst = task.status == KanbanController.statuses.first;
    final isLast = task.status == KanbanController.statuses.last;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isFirst)
                  _actionButton(
                    icon: Icons.arrow_back_ios_rounded,
                    color: Colors.grey.shade600,
                    onTap: () => controller.moveBack(task),
                  ),
                if (!isLast)
                  _actionButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    color: const Color.fromARGB(255, 14, 66, 109),
                    onTap: () => controller.moveForward(task),
                  ),
                _actionButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  onTap: () => controller.deleteTask(task),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
