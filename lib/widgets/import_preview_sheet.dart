import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/models/column_data.dart';

class ImportPreviewSheet extends StatefulWidget {
  final List<Map<String, String>> tasks;
  final List<ColumnData> columns;

  const ImportPreviewSheet({
    super.key,
    required this.tasks,
    required this.columns,
  });

  @override
  State<ImportPreviewSheet> createState() => _ImportPreviewSheetState();
}

class _ImportPreviewSheetState extends State<ImportPreviewSheet> {
  late List<bool> _selected;
  late String _columnId;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    // all tasks selected by default so the user only has to deselect what they don't want
    _selected = List.filled(widget.tasks.length, true);
    _columnId = widget.columns.isNotEmpty ? widget.columns.first.id : '';
  }

  int _getSelectedCount() {
    return _selected.where((s) => s).length;
  }

  Future<void> _import() async {
    List<Map<String, String>> toImport = [];
    for (int i = 0; i < widget.tasks.length; i++) {
      if (_selected[i]) toImport.add(widget.tasks[i]);
    }

    if (toImport.isEmpty || _columnId.isEmpty) return;

    setState(() => _isImporting = true);

    await Get.find<KanbanController>().importTasks(toImport, _columnId);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = _getSelectedCount();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color.fromARGB(255, 14, 66, 109),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.tasks.length} tasks generated',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$selectedCount selected for import',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _columnId.isEmpty ? null : _columnId,
                      decoration: const InputDecoration(
                        labelText: 'Import into column',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.view_column_outlined),
                      ),
                      items: widget.columns.map((ColumnData col) {
                        return DropdownMenuItem<String>(
                          value: col.id,
                          child: Text(col.label),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) setState(() => _columnId = value);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: widget.tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    Map<String, String> task = widget.tasks[index];
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _selected[index],
                      onChanged: (bool? value) {
                        setState(() => _selected[index] = value ?? false);
                      },
                      title: Text(
                        task['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        task['description'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      activeColor: const Color.fromARGB(255, 14, 66, 109),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (selectedCount == 0 || _isImporting) ? null : _import,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 14, 66, 109),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isImporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Import $selectedCount task${selectedCount == 1 ? '' : 's'}',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
