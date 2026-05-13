import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/subtask_data.dart';
import 'package:quiz/widgets/my_task_list.dart';

// A list of colors to cycle through for the column headers
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

  // Pick a header color based on the column's position in the board
  Color get _headerColor {
    int index = column.order % _columnColors.length;
    return _columnColors[index];
  }

  // Show a dialog asking the user to confirm before deleting the column
  void _showDeleteColumnDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Delete "${column.label}"?'),
        content: const Text(
          'This will permanently delete the column and all its tasks.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteColumn(column.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show a dialog that lets the user type a title for a new task
  void _showAddTaskDialog() {
    TextEditingController titleController = TextEditingController();

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
          onSubmitted: (String value) {
            _submitAddTask(titleController);
          },
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitAddTask(titleController);
            },
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

  // Add the task if the title is not empty, then close the dialog
  void _submitAddTask(TextEditingController titleController) {
    String title = titleController.text.trim();
    if (title.isNotEmpty) {
      controller.addTask(title, column.id);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<Subtask> tasks = controller.tasksFor(column.id);

      return SizedBox(
        width: 300,
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
              // Column header bar with label, task count, add, and delete buttons
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _headerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Column name
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

                    // Task count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Add task button
                    GestureDetector(
                      onTap: _showAddTaskDialog,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Delete column button
                    GestureDetector(
                      onTap: _showDeleteColumnDialog,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Show an empty message if there are no tasks, otherwise show the task list
              if (tasks.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ),
                )
              else
                MyTaskList(
                  tasks: tasks,
                  columns: controller.columns,
                  onDelete: controller.deleteTask,
                  onUpdate: controller.updateTask,
                ),
            ],
          ),
        ),
      );
    });
  }
}
