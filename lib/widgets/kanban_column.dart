import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/kanban_column_data.dart';
import 'package:quiz/widgets/my_task_list.dart';

const List<Color> _columnColors = [
  Color.fromARGB(255, 14, 66, 109),
  Color(0xFF2E7D32),
  Color(0xFFE65100),
  Color(0xFF6A1B9A),
  Color(0xFF00695C),
  Color(0xFFC62828),
];

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.column,
    required this.controller,
  });

  final ColumnData column;
  final KanbanController controller;

  Color get _headerColor => _columnColors[column.order % _columnColors.length];

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('Add task to "${column.label}"'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Task title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitAddTask(titleController),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _submitAddTask(titleController),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 14, 66, 109),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _submitAddTask(TextEditingController titleController) {
    final title = titleController.text.trim();
    if (title.isNotEmpty) {
      controller.addTask(title, column.id);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = controller.tasksFor(column.id);
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
                children: [
                  Expanded(
                    child: Text(
                      column.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showAddTaskDialog,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 18),
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
                columnData: KanbanColumnData(label: column.label, tasks: tasks),
                columns: controller.columns,
                onDelete: controller.deleteTask,
                onUpdate: controller.updateTask,
              ),
          ],
        ),
      ),
    );
  }
}
