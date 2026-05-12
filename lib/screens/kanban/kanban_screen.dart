import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/widgets/kanban_column.dart';

class KanbanScreen extends StatelessWidget {
  KanbanScreen({super.key});

  final KanbanController controller = Get.put(KanbanController());

  void _showAddColumnDialog() {
    final labelController = TextEditingController();
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
          onSubmitted: (_) => _submitAddColumn(labelController),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _submitAddColumn(labelController),
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
    final label = labelController.text.trim();
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: controller.columns
              .map((col) => KanbanColumn(key: ValueKey(col.id), column: col, controller: controller))
              .toList(),
        );
      }),
    );
  }
}
