import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/widgets/task_card_widget.dart';

// MyTaskList shows all the task cards inside a single kanban column.
// It handles two interactions: swipe to delete, and long-press to drag.
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
    // ListView.builder only builds the cards that are currently visible on screen,
    // which is more efficient than building all of them at once.
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        Task task = tasks[index];

        // Dismissible makes a widget swipeable.
        // Swiping from right to left shows the red delete background.
        return Dismissible(
          // Each Dismissible MUST have a unique key so Flutter can tell them apart
          key: ValueKey(task.id),

          // Only allow swiping from right to left (endToStart)
          direction: DismissDirection.endToStart,

          // The red background that appears while the user is swiping
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),

          // confirmDismiss is called before the card disappears.
          // If we return true, the card disappears. If false, it bounces back.
          confirmDismiss: (DismissDirection direction) async {
            // Start with false — the user hasn't confirmed yet
            bool userSaidYes = false;

            // Show a warning dialog asking if they really want to delete
            await AwesomeDialog(
              context: context,
              dialogType: DialogType.warning,
              animType: AnimType.bottomSlide,
              title: 'Delete Task',
              desc: 'Are you sure you want to delete this task?',
              btnCancelOnPress: () {
                userSaidYes = false; // they pressed Cancel
              },
              btnOkOnPress: () {
                userSaidYes = true; // they pressed OK
              },
            ).show();

            // Return the user's decision — true means go ahead and delete
            return userSaidYes;
          },

          // This only runs if confirmDismiss returned true
          onDismissed: (DismissDirection direction) {
            onDelete(task);
          },

          // LongPressDraggable wraps the card so the user can drag it to another column.
          // The generic type <Task> tells Flutter what kind of data is being dragged.
          child: LongPressDraggable<Task>(
            // This is the data that gets passed to the DragTarget when dropped
            data: task,

            // The user must hold for 250ms before the drag starts (prevents accidental drags)
            delay: const Duration(milliseconds: 250),

            // This is the mini card that floats under the user's finger while dragging
            feedback: Material(
              elevation: 8, // gives it a shadow to make it look like it's floating
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
                    decoration: TextDecoration.none, // prevent default underline in Material
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // While dragging, show a faded ghost of the card in its original position
            childWhenDragging: Opacity(
              opacity: 0.3, // 30% visible — just a ghost
              child: TaskCardWidget(
                task: task,
                columns: columns,
                onUpdate: onUpdate,
              ),
            ),

            // The normal card that shows when nothing is being dragged
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
