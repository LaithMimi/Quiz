import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
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

  Color get _headerColor {
    int colorIndex = column.order % _columnColors.length;
    return _columnColors[colorIndex];
  }

  void _showRenameDialog() {
    TextEditingController nameController =
        TextEditingController(text: column.label);

    Get.dialog(
      AlertDialog(
        title: const Text('Rename Column'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'New column name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitRename(nameController),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitRename(nameController),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 14, 66, 109),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _submitRename(TextEditingController nameController) {
    String newLabel = nameController.text.trim();
    if (newLabel.isNotEmpty && newLabel != column.label) {
      controller.renameColumn(column.id, newLabel);
    }
    Get.back();
  }

  void _showDeleteColumnDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Delete "${column.label}"?'),
        content: const Text('This will permanently delete the column and all its tasks.'),
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
      List<Task> tasks = controller.tasksFor(column.id);
      int overdueCount = controller.overdueCountFor(column.id);

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

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _headerColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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

                    if (overdueCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$overdueCount overdue',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],

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
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),

                    const SizedBox(width: 6),

                    GestureDetector(
                      onTap: _showRenameDialog,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                      ),
                    ),

                    const SizedBox(width: 6),

                    GestureDetector(
                      onTap: _showDeleteColumnDialog,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: DragTarget<Task>(
                  onAcceptWithDetails: (DragTargetDetails<Task> details) {
                    Task droppedTask = details.data;
                    if (droppedTask.columnId != column.id) {
                      Task movedTask = droppedTask.copyWith(columnId: column.id);
                      controller.updateTask(movedTask);
                    }
                  },
                  builder: (
                    BuildContext context,
                    List<Task?> candidateData,
                    List<dynamic> rejectedData,
                  ) {
                    bool cardIsHovering = candidateData.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardIsHovering
                            ? const Color(0xFF6B4EFF).withValues(alpha: 0.05)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: tasks.isEmpty
                          ? Center(
                              child: Text(
                                cardIsHovering ? 'Drop here' : 'No tasks',
                                style: TextStyle(
                                  color: cardIsHovering
                                      ? const Color(0xFF6B4EFF)
                                      : Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : MyTaskList(
                              tasks: tasks,
                              columns: controller.columns,
                              onDelete: controller.deleteTask,
                              onUpdate: controller.updateTask,
                            ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      );
    });
  }
}
