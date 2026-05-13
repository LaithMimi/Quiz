import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/services/ai_service.dart';
import 'package:quiz/services/document_service.dart';
import 'package:quiz/widgets/import_preview_sheet.dart';
import 'package:quiz/widgets/kanban_column.dart';

class KanbanScreen extends StatelessWidget {
  KanbanScreen({super.key});

  // Create and register the controller so it can be found anywhere in the widget tree
  final KanbanController controller = Get.put(KanbanController());

  // Pick a document, extract its text, generate tasks with AI, then show a preview
  Future<void> _importFromDocument() async {
    // Step 1: Let the user pick a file and read its text
    String? text = await DocumentService.pickAndExtractText();

    if (text == null || text.trim().isEmpty) {
      return;
    }

    // Make sure there is at least one column to import tasks into
    if (controller.columns.isEmpty) {
      Get.snackbar(
        'No columns',
        'Add at least one column before importing tasks.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Step 2: Show a loading dialog while the AI processes the document
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

    // Step 3: Ask the AI to extract tasks from the document text
    List<Map<String, String>> tasks;
    try {
      tasks = await AIService.generateTasksFromDocument(text);
    } catch (e) {
      Get.back(); // close loading dialog
      Get.snackbar(
        'Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Close the loading dialog
    Get.back();

    // Show an error if the AI returned no tasks
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

    // Step 4: Show the preview sheet so the user can review and select tasks
    await showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ImportPreviewSheet(
          tasks: tasks,
          columns: controller.columns,
        );
      },
    );
  }

  // Show a dialog that lets the user type a name for a new column
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

  // Add the column if the name is not empty, then close the dialog
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddColumnDialog,
        backgroundColor: const Color.fromARGB(255, 14, 66, 109),
        foregroundColor: Colors.white,
        tooltip: 'Add column',
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        // Show a loading spinner while data is being fetched from Firestore
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show an empty state message if there are no columns yet
        if (controller.columns.isEmpty) {
          return Center(
            child: Text(
              'No columns yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          );
        }

        // Show the columns in a horizontally scrollable row
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: constraints.maxHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: controller.columns.map((col) {
                    return KanbanColumn(
                      key: ValueKey(col.id),
                      column: col,
                      controller: controller,
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
