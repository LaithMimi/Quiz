import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/services/ai_service.dart';
import 'package:quiz/services/auth_service.dart';
import 'package:quiz/services/document_service.dart';
import 'package:quiz/widgets/import_preview_sheet.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/widgets/kanban_column.dart';

class KanbanScreen extends StatelessWidget {
  KanbanScreen({super.key});

  final KanbanController controller = Get.put(KanbanController());

  Future<void> _importFromDocument() async {
    String? text = await DocumentService.pickAndExtractText();

    if (text == null || text.trim().isEmpty) {
      return;
    }

    if (controller.columns.isEmpty) {
      Get.snackbar(
        'No columns',
        'Add at least one column before importing tasks.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.dialog(
      const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Analysing document and generating tasks…')),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    List<Map<String, String>> tasks;
    try {
      tasks = await AIService.generateTasksFromDocument(text);
    } catch (error) {
      Get.back();
      Get.snackbar(
        'Failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    Get.back();

    if (tasks.isEmpty) {
      Get.snackbar(
        'Failed',
        'No tasks could be extracted from this document.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    await showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true, // lets the sheet be taller than half the screen
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ImportPreviewSheet(tasks: tasks, columns: controller.columns);
      },
    );
  }

  void _showAddColumnDialog() {
    TextEditingController labelController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('New Column'),
        content: TextField(
          controller: labelController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Column name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (String value) {
            _submitAddColumn(labelController);
          },
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitAddColumn(labelController);
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

  void _submitAddColumn(TextEditingController labelController) {
    String label = labelController.text.trim();
    if (label.isNotEmpty) {
      controller.addColumn(label);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Kanban Board'),
        backgroundColor: const Color.fromARGB(255, 14, 66, 109),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Import from document',
            onPressed: _importFromDocument,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await AuthService.signOut();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              onChanged: (String typedText) {
                controller.searchQuery.value = typedText;
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddColumnDialog,
        backgroundColor: const Color.fromARGB(255, 14, 66, 109),
        foregroundColor: Colors.white,
        tooltip: 'Add column',
        child: const Icon(Icons.add),
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.columns.isEmpty) {
          return Center(
            child: Text(
              'No columns yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          );
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: constraints.maxHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (ColumnData col in controller.columns)
                      KanbanColumn(
                        key: ValueKey(col.id), // unique key helps Flutter update correctly
                        column: col,
                        controller: controller,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
