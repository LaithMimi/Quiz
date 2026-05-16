import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/widgets/task_card_widget.dart';

class MyTaskList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        Task task = tasks[index];

        return Dismissible(
          // each Dismissible needs a unique key or Flutter can't tell them apart
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (DismissDirection direction) async {
            bool userSaidYes = false;

            await AwesomeDialog(
              context: context,
              dialogType: DialogType.warning,
              animType: AnimType.bottomSlide,
              title: 'Delete Task',
              desc: 'Are you sure you want to delete this task?',
              btnCancelOnPress: () {
                userSaidYes = false;
              },
              btnOkOnPress: () {
                userSaidYes = true;
              },
            ).show();

            return userSaidYes;
          },
          onDismissed: (DismissDirection direction) {
            onDelete(task);
          },
          child: LongPressDraggable<Task>(
            data: task,
            // delay prevents accidental drags when the user just wants to scroll
            delay: const Duration(milliseconds: 250),
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    decoration: TextDecoration.none, // prevents the default underline Material adds in drag feedback
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: TaskCardWidget(
                task: task,
                columns: columns,
                onUpdate: onUpdate,
              ),
            ),
            child: TaskCardWidget(
              task: task,
              columns: columns,
              onUpdate: onUpdate,
            ),
          ),
        );
      },
    );
  }
}
