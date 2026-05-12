import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/subtask_data.dart';

class TaskCardWidget extends StatefulWidget {
  final Subtask task;
  final List<ColumnData> columns;
  final void Function(Subtask updated) onUpdate;

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
      builder: (_) => _EditTaskSheet(
        task: widget.task,
        columns: widget.columns,
        onSave: widget.onUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtask = widget.task;
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
                    const SizedBox(width: 12),
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
                              const Icon(Icons.person_outline,
                                  size: 13, color: Colors.black45),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  subtask.username.isEmpty
                                      ? 'Unassigned'
                                      : subtask.username,
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
                              const Icon(Icons.calendar_today_outlined,
                                  size: 13, color: Colors.black45),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 19, color: Color(0xFF6B4EFF)),
                      onPressed: _showEditSheet,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF6B4EFF),
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditTaskSheet extends StatefulWidget {
  final Subtask task;
  final List<ColumnData> columns;
  final void Function(Subtask updated) onSave;

  const _EditTaskSheet({
    required this.task,
    required this.columns,
    required this.onSave,
  });

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _description;
  late final TextEditingController _goal;
  late final TextEditingController _techstack;
  late String _columnId;
  DateTime? _duedate;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title       = TextEditingController(text: t.title);
    _username    = TextEditingController(text: t.username);
    _description = TextEditingController(text: t.description ?? '');
    _goal        = TextEditingController(text: t.goal ?? '');
    _techstack   = TextEditingController(text: t.techstack ?? '');
    _columnId    = t.columnId;
    _duedate     = t.duedate;
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _description.dispose();
    _goal.dispose();
    _techstack.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _duedate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _duedate = picked);
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    widget.onSave(
      widget.task.copyWith(
        title: _title.text.trim(),
        columnId: _columnId,
        username: _username.text.trim(),
        description: _description.text.trim(),
        goal: _goal.text.trim(),
        techstack: _techstack.text.trim(),
        duedate: _duedate,
      ),
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Task',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field('Title', _title),
            const SizedBox(height: 12),
            _field('Assigned to', _username),
            const SizedBox(height: 12),
            _field('Description', _description, maxLines: 3),
            const SizedBox(height: 12),
            _field('Goal', _goal, maxLines: 2),
            const SizedBox(height: 12),
            _field('Tech Stack', _techstack),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _columnId.isEmpty ? null : _columnId,
              decoration: const InputDecoration(
                labelText: 'Column',
                border: OutlineInputBorder(),
              ),
              items: widget.columns
                  .map((col) => DropdownMenuItem(
                        value: col.id,
                        child: Text(col.label),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _columnId = val);
              },
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 14, 66, 109),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
