import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/widgets/edit_task_sheet.dart';

// The card shown for each task in a kanban column
class TaskCardWidget extends StatefulWidget {
  final Task task;
  final List<ColumnData> columns;
  final void Function(Task updated) onUpdate;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.columns,
    required this.onUpdate,
  });

  @override
  State<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<TaskCardWidget> {
  bool _isExpanded = false;

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return EditTaskSheet(
          task: widget.task,
          columns: widget.columns,
          onSave: widget.onUpdate,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Task task = widget.task;
    String formattedDate = DateFormat('MMM dd, yyyy').format(
      task.duedate ?? task.date,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
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
            // Tapping this row expands or collapses the details below
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Task icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EBFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.check_box_outlined,
                        color: Color(0xFF6B4EFF),
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Task title, assignee, and date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 13, color: Colors.black45),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  task.username.isEmpty ? 'Unassigned' : task.username,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(width: 1, height: 11, color: Colors.grey.shade300),
                              const SizedBox(width: 6),
                              const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.black45),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF6B4EFF)),
                      onPressed: _showEditSheet,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const SizedBox(width: 6),

                    // Expand/collapse arrow
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF6B4EFF),
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded detail section shown when the user taps the card
            if (_isExpanded) ...[
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
                      isLast: task.sharedWith == null && task.sharedBy == null,
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
  }

  // Build a single row in the timeline-style detail section
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon and vertical connector line
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
        // Label and value text
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
