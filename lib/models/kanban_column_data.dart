import 'package:quiz/models/task_data.dart';

class KanbanColumnData {
  final String label;
  final List<Task> tasks;

  KanbanColumnData({required this.label, required this.tasks});
}
