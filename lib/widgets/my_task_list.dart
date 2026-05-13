import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/widgets/task_card_widget.dart';

class MyTaskList extends StatefulWidget {
  final List<Task> tasks;
  final List<ColumnData> columns;
  final void Function(Task task) onDelete;
  final void Function(Task updated) onUpdate;

  const MyTaskList({
    super.key,
    required this.tasks,
    required this.columns,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<MyTaskList> createState() => _MyTaskListState();
}

class _MyTaskListState extends State<MyTaskList> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              bool confirmed = false;
              await AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                animType: AnimType.bottomSlide,
                title: 'Delete Task',
                desc: 'Are you sure you want to delete this task?',
                btnCancelOnPress: () => confirmed = false,
                btnOkOnPress: () => confirmed = true,
              ).show();
              return confirmed;
            },
            onDismissed: (_) => widget.onDelete(task),
            child: TaskCardWidget(
              task: task,
              columns: widget.columns,
              onUpdate: widget.onUpdate,
            ),
          );
        },
      ),
    );
  }
}
