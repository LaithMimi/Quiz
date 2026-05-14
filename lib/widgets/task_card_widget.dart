import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/widgets/edit_task_sheet.dart';

class TaskCardWidget extends StatelessWidget {
  final Task task;
  final List<ColumnData> columns;
  final void Function(Task updated) onUpdate;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.columns,
    required this.onUpdate,
  });

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
    final KanbanController controller = Get.find<KanbanController>();

    return Obx(() {
      final bool isExpanded = controller.isTaskExpanded(task.id);
      final bool isOverdue = !task.isCompleted &&
          task.duedate != null &&
          task.duedate!.isBefore(DateTime.now());
      final String formattedDate =
          DateFormat('MMM dd, yyyy').format(task.duedate ?? task.date);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: task.isCompleted ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
            ),
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
              InkWell(
                onTap: () => controller.toggleExpanded(task.id),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Completion toggle
                      GestureDetector(
                        onTap: () => controller.toggleComplete(task),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? const Color(0xFF6B4EFF).withValues(alpha: 0.15)
                                : const Color(0xFFF0EBFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            task.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: const Color(0xFF6B4EFF),
                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: task.isCompleted
                                    ? Colors.grey
                                    : Colors.black87,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 13, color: Colors.black45),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    task.username.isEmpty
                                        ? 'Unassigned'
                                        : task.username,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                    width: 1,
                                    height: 11,
                                    color: Colors.grey.shade300),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: isOverdue
                                      ? Colors.red
                                      : Colors.black45,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOverdue
                                          ? Colors.red
                                          : Colors.black54,
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

                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 19, color: Color(0xFF6B4EFF)),
                        onPressed: () => _showEditSheet(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                      const SizedBox(width: 6),

                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF6B4EFF),
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),

              if (isExpanded) ...[
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTimelineItem(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        subtitle: (task.description ?? '').isEmpty
                            ? 'No description provided.'
                            : task.description!,
                        isLast: false,
                      ),
                      _buildTimelineItem(
                        icon: Icons.access_time,
                        title: 'Due Date',
                        subtitle: formattedDate,
                        isLast:
                            task.sharedWith == null && task.sharedBy == null,
                      ),
                      if (task.sharedWith != null)
                        _buildTimelineItem(
                          icon: Icons.send,
                          title: 'Assigned to',
                          subtitle: task.sharedWith!,
                          isLast: task.sharedBy == null,
                        ),
                      if (task.sharedBy != null)
                        _buildTimelineItem(
                          icon: Icons.move_to_inbox,
                          title: 'Shared by',
                          subtitle: task.sharedBy!,
                          isLast: true,
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

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
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
