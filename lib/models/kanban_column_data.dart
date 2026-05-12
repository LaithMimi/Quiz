import 'package:quiz/models/subtask_data.dart';

class KanbanColumnData {
  final String label;
  final List<Subtask> tasks;

  KanbanColumnData({required this.label, required this.tasks});
}
