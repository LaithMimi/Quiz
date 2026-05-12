import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:quiz/models/kanban_column_data.dart';
import 'package:quiz/widgets/task_card_widget.dart';

class MyTaskList extends StatefulWidget {
  final KanbanColumnData columnData;
  final void Function(int index) onDelete;

  const MyTaskList({
    super.key,
    required this.columnData,
    required this.onDelete,
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
        itemCount: widget.columnData.tasks.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              bool deleteConfirmed = false;

              await AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                animType: AnimType.bottomSlide,
                title: 'Delete Task',
                desc: 'Are you sure you want to delete this task?',
                btnCancelOnPress: () {
                  deleteConfirmed = false;
                },
                btnOkOnPress: () {
                  deleteConfirmed = true;
                },
              ).show();

              return deleteConfirmed;
            },
            onDismissed: (direction) {
              widget.onDelete(index);
            },
            child: TaskCardWidget(task: widget.columnData.tasks[index]),
          );
        },
      ),
    );
  }
}
