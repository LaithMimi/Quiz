import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/widgets/my_task_list.dart';

// These are the header colors that columns cycle through.
// Column 0 gets color 0, column 1 gets color 1, and so on.
// When we run out of colors, we loop back to the start (using %).
const List<Color> _columnColors = [
  Color.fromARGB(255, 14, 66, 109),
  Color(0xFF2E7D32),
  Color(0xFFE65100),
  Color(0xFF6A1B9A),
  Color(0xFF00695C),
  Color(0xFFC62828),
];

// KanbanColumn renders one full column on the board, including:
// - the colored header bar (with name, count badge, and buttons)
// - the list of task cards below it
// - drag-and-drop support (you can drop cards from other columns here)
class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.column,
    required this.controller,
  });

  final ColumnData column;
  final KanbanController controller;

  // Pick a color based on this column's order position.
  // The % (modulo) operator wraps around: if there are 6 colors and this is column 7,
  // we get 7 % 6 = 1, so it reuses color index 1.
  Color get _headerColor {
    int colorIndex = column.order % _columnColors.length;
    return _columnColors[colorIndex];
  }

  // Show a confirmation dialog before deleting the column
  void _showDeleteColumnDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Delete "${column.label}"?'),
        content: const Text('This will permanently delete the column and all its tasks.'),
        actions: [
          TextButton(
            onPressed: Get.back, // close the dialog without doing anything
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // close the dialog first
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

  // Show a dialog where the user can type a title for a new task
  void _showAddTaskDialog() {
    TextEditingController titleController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Add task to "${column.label}"'),
        content: TextField(
          controller: titleController,
          autofocus: true, // keyboard opens automatically
          decoration: const InputDecoration(
            hintText: 'Task title',
            border: OutlineInputBorder(),
          ),
          // Let the user press Enter to submit instead of tapping the button
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

  // Only add the task if the user actually typed something
  void _submitAddTask(TextEditingController titleController) {
    String title = titleController.text.trim(); // trim removes leading/trailing spaces
    if (title.isNotEmpty) {
      controller.addTask(title, column.id);
      Get.back(); // close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obx watches observable (.obs) values and rebuilds this widget when they change.
    // Here it reacts to changes in tasks and columns.
    return Obx(() {
      // Get the tasks for this column (already filtered by search and sorted)
      List<Task> tasks = controller.tasksFor(column.id);

      // Count overdue tasks to decide if we show the red badge
      int overdueCount = controller.overdueCountFor(column.id);

      return SizedBox(
        width: 300, // each column is a fixed 300px wide
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

              // ── HEADER BAR ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _headerColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    // Column name — clips with "..." if it's too long
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

                    // White pill badge showing total task count
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

                    // Red badge that only appears when there are overdue tasks
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

                    // "+" button to add a new task to this column
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

                    // Trash button to delete this whole column
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

              // ── BODY WITH DRAG-AND-DROP ────────────────────────────────
              // Expanded makes this section fill all the remaining vertical space.
              // DragTarget is an invisible drop zone — it activates when a dragged
              // task card is released over it.
              Expanded(
                child: DragTarget<Task>(

                  // This runs when the user drops a task card here.
                  // "details.data" is the Task object that was being dragged.
                  onAcceptWithDetails: (DragTargetDetails<Task> details) {
                    Task droppedTask = details.data;

                    // Only move the task if it's coming from a different column
                    // (no point moving it to the same column it's already in)
                    if (droppedTask.columnId != column.id) {
                      // copyWith creates a new task with only columnId changed
                      Task movedTask = droppedTask.copyWith(columnId: column.id);
                      controller.updateTask(movedTask);
                    }
                  },

                  // builder draws what the body looks like.
                  // candidateData is a list of tasks currently hovering over this column
                  // (it's non-empty while someone is dragging a card over us).
                  builder: (
                    BuildContext context,
                    List<Task?> candidateData,
                    List<dynamic> rejectedData,
                  ) {
                    // Is a task card currently hovering above this column?
                    bool cardIsHovering = candidateData.isNotEmpty;

                    // AnimatedContainer smoothly transitions the background color
                    // when a card starts hovering over this column
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // Subtle purple tint when a card is hovering over us
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
                                // Change the hint text when a card is hovering
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
