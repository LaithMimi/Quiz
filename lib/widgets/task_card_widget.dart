import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiz/models/subtask_data.dart';

class TaskCardWidget extends StatefulWidget {
  final Subtask task;

  const TaskCardWidget({super.key, required this.task});

  @override
  State<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<TaskCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final subtask = widget.task;
    final user = subtask.username;
    final formattedDate =
        DateFormat('MMM dd, yyyy').format(subtask.duedate ?? subtask.date);

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
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtask.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 14, color: Colors.black45),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  user,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                  width: 1,
                                  height: 12,
                                  color: Colors.grey.shade300),
                              const SizedBox(width: 8),
                              const Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Colors.black45),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF6B4EFF),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildTimelineItem(
                      icon: Icons.description_outlined,
                      title: 'Description',
                      subtitle: (subtask.description ?? '').isEmpty
                          ? 'No description provided.'
                          : subtask.description!,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.flag_outlined,
                      title: 'Goal',
                      subtitle: (subtask.goal ?? '').isEmpty
                          ? 'No goal provided.'
                          : subtask.goal!,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.code,
                      title: 'Tech Stack',
                      subtitle: (subtask.techstack ?? '').isEmpty
                          ? 'No tech stack provided.'
                          : subtask.techstack!,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.access_time,
                      title: 'Due Date',
                      subtitle: formattedDate,
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
