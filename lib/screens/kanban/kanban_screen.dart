import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/services/ai_service.dart';
import 'package:quiz/services/auth_service.dart';
import 'package:quiz/services/document_service.dart';
import 'package:quiz/widgets/import_preview_sheet.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/widgets/kanban_column.dart';

// KanbanScreen is the main board screen the user sees after logging in.
// It shows all the columns side by side in a horizontal scroll view.
class KanbanScreen extends StatelessWidget {
  KanbanScreen({super.key});

  // Get.put creates the KanbanController and registers it with GetX.
  // From this point on, any widget can call Get.find<KanbanController>() to get it.
  final KanbanController controller = Get.put(KanbanController());

  // Handles the full flow of importing tasks from a document file:
  // 1. Let the user pick a file
  // 2. Show a loading dialog
  // 3. Ask the AI to extract tasks
  // 4. Show a preview sheet so the user can choose which tasks to import
  Future<void> _importFromDocument() async {
    // Step 1: Open the file picker and read the text from the chosen file
    String? text = await DocumentService.pickAndExtractText();

    // If the user cancelled the file picker or the file was empty, stop here
    if (text == null || text.trim().isEmpty) {
      return;
    }

    // We need at least one column to put the imported tasks into
    if (controller.columns.isEmpty) {
      Get.snackbar(
        'No columns',
        'Add at least one column before importing tasks.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Step 2: Show a loading spinner while the AI is working
    // barrierDismissible: false means the user can't close it by tapping outside
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
    } catch (error) {
      Get.back(); // close the loading dialog before showing the error
      Get.snackbar(
        'Failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Close the loading dialog now that the AI is done
    Get.back();

    // If the AI didn't find any tasks, let the user know
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

    // Step 4: Show the preview sheet so the user can pick which tasks to import
    await showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true, // lets the sheet be taller than half the screen
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ImportPreviewSheet(tasks: tasks, columns: controller.columns);
      },
    );
  }

  // Show a dialog where the user types a name for a new column
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
          // Allow submitting by pressing Enter
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

  // Only create the column if the user actually typed a name
  void _submitAddColumn(TextEditingController labelController) {
    String label = labelController.text.trim();
    if (label.isNotEmpty) {
      controller.addColumn(label);
      Get.back(); // close the dialog
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
        // A search bar is placed below the app bar title using "bottom"
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48), // how tall the search bar area is
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              // Every time the user types a character, update the search query.
              // The columns will filter themselves automatically because searchQuery is .obs
              onChanged: (String typedText) {
                controller.searchQuery.value = typedText;
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                // Normal border (when the text field is not focused)
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                // Brighter border when the user is typing
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),

      // The "+" button in the bottom-right corner to add a new column
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddColumnDialog,
        backgroundColor: const Color.fromARGB(255, 14, 66, 109),
        foregroundColor: Colors.white,
        tooltip: 'Add column',
        child: const Icon(Icons.add),
      ),

      body: Obx(() {
        // Show a loading spinner while we wait for Firestore to send us data
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show a friendly message if there are no columns yet
        if (controller.columns.isEmpty) {
          return Center(
            child: Text(
              'No columns yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          );
        }

        // LayoutBuilder lets us know exactly how much space we have.
        // We use it to give the columns the full screen height.
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal, // scroll left and right between columns
              child: SizedBox(
                height: constraints.maxHeight, // use the full available height
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Build one KanbanColumn widget for each column in our list
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
