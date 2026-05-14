import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';

class EditTaskSheet extends StatefulWidget {
  final Task task;
  final List<ColumnData> columns;
  final void Function(Task updated) onSave;

  const EditTaskSheet({
    super.key,
    required this.task,
    required this.columns,
    required this.onSave,
  });

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
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

  Future<void> _generateDescription() async {
    String title = _title.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      String description = await Get.find<KanbanController>().generateTaskDescription(title);
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

  Future<void> _assign() async {
    String email = _assignEmail.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isAssigning = true;
    });

    Navigator.pop(context);
    await Get.find<KanbanController>().assignTaskByEmail(widget.task, email);

    setState(() {
      _isAssigning = false;
    });
  }

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
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildField('Title', _title),

            const SizedBox(height: 12),

            _buildField('Assigned to', _username),

            const SizedBox(height: 12),

            _buildField('Description', _description, maxLines: 3),

            const SizedBox(height: 8),

            // Generate description with AI
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generateDescription,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(_isGenerating ? 'Generating…' : 'Generate Description with AI'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 14, 66, 109),
                  side: const BorderSide(color: Color.fromARGB(255, 14, 66, 109)),
                ),
              ),
            ),

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

            // Email input and Assign button
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
