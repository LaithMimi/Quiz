import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';

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

  // Open the bottom sheet that lets the user edit this task
  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return _EditTaskSheet(
          task: widget.task,
          columns: widget.columns,
          onSave: widget.onUpdate,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Task subtask = widget.task;
    String formattedDate = DateFormat('MMM dd, yyyy').format(
      subtask.duedate ?? subtask.date,
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
                            subtask.title,
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
                                  subtask.username.isEmpty ? 'Unassigned' : subtask.username,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(width: 1, height: 11, color: Colors.grey.shade300),
                              const SizedBox(width: 6),
                              const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.black45),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                      subtitle: (subtask.description ?? '').isEmpty
                          ? 'No description provided.'
                          : subtask.description!,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      icon: Icons.access_time,
                      title: 'Due Date',
                      subtitle: formattedDate,
                      isLast: subtask.sharedWith == null && subtask.sharedBy == null,
                    ),
                    if (subtask.sharedWith != null)
                      _buildTimelineItem(
                        icon: Icons.send,
                        title: 'Assigned to',
                        subtitle: subtask.sharedWith!,
                        isLast: subtask.sharedBy == null,
                      ),
                    if (subtask.sharedBy != null)
                      _buildTimelineItem(
                        icon: Icons.move_to_inbox,
                        title: 'Shared by',
                        subtitle: subtask.sharedBy!,
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

// The bottom sheet that lets the user edit a task
class _EditTaskSheet extends StatefulWidget {
  final Task task;
  final List<ColumnData> columns;
  final void Function(Task updated) onSave;

  const _EditTaskSheet({
    required this.task,
    required this.columns,
    required this.onSave,
  });

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late TextEditingController _title;
  late TextEditingController _username;
  late TextEditingController _description;
  late TextEditingController _assignEmail;
  late String _columnId;
  DateTime? _duedate;
  bool _isAssigning = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();

    Task t = widget.task;

    // Pre-fill the form with the current task values
    _title = TextEditingController(text: t.title);
    _username = TextEditingController(text: t.username);
    _description = TextEditingController(text: t.description ?? '');
    _assignEmail = TextEditingController();
    _columnId = t.columnId;
    _duedate = t.duedate;
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _description.dispose();
    _assignEmail.dispose();
    super.dispose();
  }

  // Use the AI to fill in the description field.
  // The View asks the Controller — the Controller asks the Service.
  // This widget never imports AIService directly.
  Future<void> _generate() async {
    String title = _title.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      String description = await Get.find<KanbanController>().generateTaskDescription(title);

      // Check mounted because the user might have closed the sheet during the API call
      if (!mounted) return;

      _description.text = description;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
    });
  }

  // Send this task to another user's board using their email
  Future<void> _assign() async {
    String email = _assignEmail.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isAssigning = true;
    });

    // Close the sheet first so the user knows the action was submitted
    Navigator.pop(context);

    await Get.find<KanbanController>().assignTaskByEmail(widget.task, email);

    setState(() {
      _isAssigning = false;
    });
  }

  // Open a date picker and save the chosen date
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _duedate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _duedate = picked;
      });
    }
  }

  // Save the task with the current form values and close the sheet
  void _save() {
    if (_title.text.trim().isEmpty) return;

    Task updatedTask = widget.task.copyWith(
      title: _title.text.trim(),
      columnId: _columnId,
      username: _username.text.trim(),
      description: _description.text.trim(),
      duedate: _duedate,
    );

    widget.onSave(updatedTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Task',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildField('Title', _title),

            const SizedBox(height: 8),

            // Generate with AI button — fills description
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(_isGenerating ? 'Generating…' : 'Generate with AI'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 14, 66, 109),
                  side: const BorderSide(color: Color.fromARGB(255, 14, 66, 109)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildField('Assigned to', _username),

            const SizedBox(height: 12),

            _buildField('Description', _description, maxLines: 3),

            const SizedBox(height: 12),

            // Dropdown to move this task to a different column
            DropdownButtonFormField<String>(
              initialValue: _columnId.isEmpty ? null : _columnId,
              decoration: const InputDecoration(
                labelText: 'Column',
                border: OutlineInputBorder(),
              ),
              items: widget.columns.map((ColumnData col) {
                return DropdownMenuItem<String>(
                  value: col.id,
                  child: Text(col.label),
                );
              }).toList(),
              onChanged: (String? val) {
                if (val != null) {
                  setState(() {
                    _columnId = val;
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            // Due date picker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _duedate != null
                      ? DateFormat('MMM dd, yyyy').format(_duedate!)
                      : 'Select a date',
                  style: TextStyle(
                    color: _duedate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider to separate task editing from task sharing
            const Divider(),

            const SizedBox(height: 8),

            const Text(
              'Assign to another user',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            // Show who the task is already assigned to, if anyone
            if (widget.task.sharedWith != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.send, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      'Already assigned to ${widget.task.sharedWith}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),

            // Email input and Assign button side by side
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _assignEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'colleague@example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isAssigning ? null : _assign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 14, 66, 109),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isAssigning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Assign'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 14, 66, 109),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build a standard text input field
  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
