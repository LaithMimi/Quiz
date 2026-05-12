import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/kanban_controller.dart';
import 'package:quiz/widgets/kanban_column.dart';

class KanbanScreen extends StatelessWidget {
  KanbanScreen({super.key});

  final KanbanController controller = Get.put(KanbanController());

  void _showAddDialog() {
    final titleController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Task title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitAdd(titleController),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitAdd(titleController),
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

  void _submitAdd(TextEditingController titleController) {
    final title = titleController.text.trim();
    if (title.isNotEmpty) {
      controller.addTask(title);
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
        onPressed: _showAddDialog,
        backgroundColor: const Color.fromARGB(255, 14, 66, 109),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: KanbanController.statuses
              .map((status) => KanbanColumn(
                    status: status,
                    label: KanbanController.columnLabels[status]!,
                    controller: controller,
                  ))
              .toList(),
        );
      }),
    );
  }
}
