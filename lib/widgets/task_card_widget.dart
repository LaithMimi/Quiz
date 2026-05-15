import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/widgets/edit_task_sheet.dart';

// TaskCardWidget is the card you see for each task on the board.
// It's a StatelessWidget because we moved all state (expanded/collapsed)
// into the KanbanController so it survives when the widget rebuilds.
class TaskCardWidget extends StatelessWidget {
  // The task this card represents
  final Task task;

  // All columns on the board (needed for the edit sheet dropdown)
  final List<ColumnData> columns;

  // A function to call when the task is saved after editing
  final void Function(Task updated) onUpdate;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.columns,
    required this.onUpdate,
  });

  // Opens the bottom sheet where the user can edit this task.
  // We pass "context" as a parameter because we need it to show the sheet.
  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows the sheet to grow tall when the keyboard opens
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return EditTaskSheet(task: task, columns: columns, onSave: onUpdate);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get.find looks up the KanbanController that was already created by KanbanScreen.
    // We don't create a new one — we reuse the existing one.
    KanbanController controller = Get.find<KanbanController>();

    // Obx is a special widget that watches for changes in observable (.obs) variables.
    // Whenever expandedIds or tasks change in the controller, this whole card rebuilds.
    return Obx(() {
      // Is this specific card currently open (showing its details)?
      bool isExpanded = controller.isTaskExpanded(task.id);

      // Figure out if this task is overdue.
      // A task is overdue if it has a due date, that date is in the past, and it's not done yet.
      bool isOverdue = false;
      if (task.duedate != null && task.isCompleted == false) {
        if (task.duedate!.isBefore(DateTime.now())) {
          isOverdue = true;
        }
      }

      // Decide which date to show: the due date if there is one, otherwise the creation date
      DateTime dateToShow;
      if (task.duedate != null) {
        dateToShow = task.duedate!;
      } else {
        dateToShow = task.date;
      }

      // Format the date as "Jan 15, 2025" instead of a raw DateTime
      String formattedDate = DateFormat('MMM dd, yyyy').format(dateToShow);

      // If overdue, show a red border. Otherwise, a subtle grey border.
      Color borderColor;
      if (isOverdue) {
        borderColor = Colors.red.shade200;
      } else {
        borderColor = Colors.grey.shade200;
      }

      // Dim the card slightly when the task is completed
      Color cardColor;
      if (task.isCompleted) {
        cardColor = Colors.grey.shade50;
      } else {
        cardColor = Colors.white;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tapping anywhere on this row toggles the card open or closed
              InkWell(
                onTap: () {
                  controller.toggleExpanded(task.id);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [

                      // Checkbox icon — tapping it marks the task done or undone
                      GestureDetector(
                        onTap: () {
                          controller.toggleComplete(task);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            // Slightly purple background when done, light purple when not
                            color: task.isCompleted
                                ? const Color(0xFF6B4EFF).withValues(alpha: 0.15)
                                : const Color(0xFFF0EBFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            // Filled checkbox if done, empty outline if not done
                            task.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: const Color(0xFF6B4EFF),
                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Task title and the small info row below it
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                // Grey and crossed-out when task is done
                                color: task.isCompleted ? Colors.grey : Colors.black87,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Small row showing the assignee and the date
                            Row(
                              children: [
                                // Calendar icon turns red if the task is overdue
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: isOverdue ? Colors.red : Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      // Red date text if overdue
                                      color: isOverdue ? Colors.red : Colors.black54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Pencil button to open the edit sheet
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF6B4EFF)),
                        onPressed: () {
                          _showEditSheet(context);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                      const SizedBox(width: 6),

                      // Arrow that shows whether the card is expanded or collapsed
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF6B4EFF),
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),

              // This section only appears when the card is open.
              // The "..." spread operator adds multiple widgets to the list at once.
              if (isExpanded) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTimelineItem(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        // Show a placeholder if there's no description
                        subtitle: (task.description ?? '').isEmpty
                            ? 'No description provided.'
                            : task.description!,
                        isLast: false,
                      ),
                      _buildTimelineItem(
                        icon: Icons.access_time,
                        title: 'Due Date',
                        subtitle: formattedDate,
                        // This item is the last one if there's no sharing info
                        isLast: task.sharedWith == null && task.sharedBy == null,
                      ),
                      // Only show "Assigned to" if the task was shared with someone
                      if (task.sharedWith != null)
                        _buildTimelineItem(
                          icon: Icons.send,
                          title: 'Assigned to',
                          subtitle: task.sharedWith!,
                          isLast: task.sharedBy == null,
                        ),
                      // Only show "Shared by" if someone sent us this task
                      if (task.sharedBy != null)
                        _buildTimelineItem(
                          icon: Icons.move_to_inbox,
                          title: 'Shared by',
                          subtitle: task.sharedBy!,
                          isLast: true, // always the last item
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // Builds one row in the details section, like "Description: ..." or "Due Date: ..."
  // isLast controls whether a vertical line is drawn below this item to connect it to the next.
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: the icon and the connecting line below it
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF6B4EFF)),
            ),
            // Draw a thin line below the icon to connect it to the next item
            // (but not below the last item — it would look weird)
            if (isLast == false)
              Container(width: 2, height: 40, color: Colors.grey.shade200),
          ],
        ),

        const SizedBox(width: 12),

        // Right side: the field name and its value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
