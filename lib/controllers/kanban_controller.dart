import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/services/ai_service.dart';
import 'package:quiz/services/user_service.dart';

// The KanbanController holds all the data and logic for the kanban board.
// It extends GetxController so GetX can manage its lifecycle automatically
// (creating it when the screen opens, destroying it when the screen closes).
class KanbanController extends GetxController {
  // These two objects let us talk to Firebase
  final FirebaseFirestore _db   = FirebaseFirestore.instance; // the database
  final FirebaseAuth      _auth = FirebaseAuth.instance;      // the login system

  // "Subscriptions" are like listeners — they watch for changes in Firestore
  // and run code automatically when something changes.
  // We store them here so we can cancel them when the screen closes.
  StreamSubscription<QuerySnapshot>? _tasksSub;
  StreamSubscription<QuerySnapshot>? _columnsSub;
  StreamSubscription<User?>?         _authSub; // watches if the user logs out

  // These lists are "observable" (the .obs part).
  // Whenever you change them, any widget wrapped in Obx() will automatically rebuild.
  final RxList<Task>       tasks   = <Task>[].obs;
  final RxList<ColumnData> columns = <ColumnData>[].obs;
  final RxBool             isLoading = true.obs; // true while we wait for first data

  // We store task IDs here when their card is open (expanded).
  // Using RxList makes the UI react when we open or close a card.
  final RxList<String> expandedIds = <String>[].obs;

  // This holds whatever the user typed in the search bar.
  // RxString means the columns will filter themselves as the user types.
  final RxString searchQuery = ''.obs;

  // A handy shortcut to get the logged-in user's ID.
  // We use this to find the right place in Firestore for this user's data.
  String get _uid {
    return _auth.currentUser!.uid;
  }

  // Shortcut to the tasks collection in Firestore for the current user.
  // The path looks like: users / {userId} / tasks
  CollectionReference<Map<String, dynamic>> get _tasksCol {
    return _db.collection('users').doc(_uid).collection('tasks');
  }

  // Shortcut to the columns collection in Firestore for the current user.
  CollectionReference<Map<String, dynamic>> get _columnsCol {
    return _db.collection('users').doc(_uid).collection('columns');
  }

  // Returns a filtered and sorted list of tasks for one column.
  // This is called inside Obx() so it runs again whenever tasks or searchQuery changes.
  List<Task> tasksFor(String columnId) {
    // Get the search text and make it lowercase so comparison is case-insensitive
    String query = searchQuery.value.toLowerCase().trim();

    List<Task> result = [];

    // Go through every task and decide whether to include it
    for (Task task in tasks) {
      // Skip tasks that belong to a different column
      if (task.columnId != columnId) {
        continue; // "continue" jumps to the next loop iteration
      }

      // If the user typed something in the search bar, only keep matching tasks
      if (query.isNotEmpty) {
        bool titleMatches       = task.title.toLowerCase().contains(query);
        bool descriptionMatches = (task.description ?? '').toLowerCase().contains(query);

        // If the task doesn't match at all, skip it
        if (titleMatches == false && descriptionMatches == false) {
          continue;
        }
      }

      result.add(task);
    }

    // Sort so completed tasks sink to the bottom of the column.
    // The sort function compares two tasks (a and b):
    //   return 0  → keep them in the same order
    //   return 1  → move a after b
    //   return -1 → move a before b
    result.sort((Task a, Task b) {
      if (a.isCompleted == b.isCompleted) {
        return 0; // both done or both not done — no change needed
      }
      if (a.isCompleted == true) {
        return 1; // a is done, push it below b
      }
      return -1; // b is done, push it below a
    });

    return result;
  }

  // Counts how many tasks in this column are past their due date and not yet done.
  // Used to show the red "N overdue" badge in the column header.
  int overdueCountFor(String columnId) {
    DateTime rightNow = DateTime.now();
    int count = 0;

    for (Task task in tasks) {
      // Only look at tasks in this column that aren't finished yet
      if (task.columnId == columnId && task.isCompleted == false) {
        // Check if this task even has a due date
        if (task.duedate != null) {
          // isBefore() returns true if the due date is earlier than right now
          if (task.duedate!.isBefore(rightNow)) {
            count = count + 1;
          }
        }
      }
    }

    return count;
  }

  // Opens a task card if it was closed, or closes it if it was open.
  void toggleExpanded(String taskId) {
    bool cardIsCurrentlyOpen = expandedIds.contains(taskId);

    if (cardIsCurrentlyOpen) {
      expandedIds.remove(taskId); // close it
    } else {
      expandedIds.add(taskId);    // open it
    }
  }

  // Returns true if the card for this task is currently showing its details.
  bool isTaskExpanded(String taskId) {
    return expandedIds.contains(taskId);
  }

  // onInit runs automatically when the controller is first created.
  // This is the right place to start listening to Firestore.
  @override
  void onInit() {
    super.onInit();

    // Watch for the user logging out.
    // authStateChanges() fires every time the login state changes.
    // If "user" is null, that means nobody is logged in anymore.
    _authSub = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // The session ended — send the user back to the login screen.
        // offAllNamed removes every screen in the stack, so back button won't work.
        Get.offAllNamed('/login');
      }
    });

    // Listen to the columns collection. When columns change in Firestore,
    // this callback runs and updates our local columns list automatically.
    _columnsSub = _columnsCol.orderBy('order').snapshots().listen(
      (QuerySnapshot snap) {
        List<ColumnData> newColumns = [];

        // Each "doc" is one column document from Firestore
        for (QueryDocumentSnapshot doc in snap.docs) {
          // doc.data() gives us a Map, but we also need the document ID
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // attach the Firestore ID to the map

          ColumnData column = ColumnData.fromJson(data);
          newColumns.add(column);
        }

        columns.value = newColumns; // this triggers all Obx() widgets to rebuild
        isLoading.value = false;    // data is here, stop showing the loading spinner
      },
      onError: (Object error) {
        showError(error);
        isLoading.value = false;
      },
    );

    // Same idea as above but for the tasks collection
    _tasksSub = _tasksCol.snapshots().listen(
      (QuerySnapshot snap) {
        List<Task> newTasks = [];

        for (QueryDocumentSnapshot doc in snap.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          Task task = Task.fromJson(data);
          newTasks.add(task);
        }

        tasks.value = newTasks;
      },
      onError: showError,
    );
  }

  // Add a brand new column to the board
  Future<void> addColumn(String label) async {
    try {
      Map<String, dynamic> columnData = {
        'label': label,
        'order': columns.length, // put it at the end of existing columns
      };
      await _columnsCol.add(columnData);
    } catch (error) {
      showError(error);
    }
  }

  // Add a brand new task to a specific column
  Future<void> addTask(String title, String columnId) async {
    try {
      Map<String, dynamic> taskData = {
        'title': title,
        'columnId': columnId,
        'date': DateTime.now().toIso8601String(),
        'isCompleted': false, // every new task starts as not done
      };
      await _tasksCol.add(taskData);
    } catch (error) {
      showError(error);
    }
  }

  // Save changes to an existing task.
  // This uses "optimistic update": we change the screen first, then save to Firestore.
  // If saving fails, we undo the screen change so nothing looks broken.
  Future<void> updateTask(Task task) async {
    // Step 1: Find this task in our local list so we know where to update it
    int indexInList = -1;
    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].id == task.id) {
        indexInList = i;
        break;
      }
    }

    // Step 2: Save a backup of the old task in case we need to undo
    Task? backup;
    if (indexInList != -1) {
      backup = tasks[indexInList];
      tasks[indexInList] = task; // update the screen right now (optimistic)
    }

    // Step 3: Try to save the change to Firestore
    try {
      Map<String, dynamic> data = task.toJson();
      data.remove('id'); // the Firestore document ID is not stored as a field inside the document
      await _tasksCol.doc(task.id).update(data);
    } catch (error) {
      // Saving failed — put the old task back so the screen is still correct
      if (indexInList != -1 && backup != null) {
        tasks[indexInList] = backup;
      }
      showError(error);
    }
  }

  // Flips the task between done and not done, then saves it
  Future<void> toggleComplete(Task task) async {
    bool newValue = !task.isCompleted; // flip it: true becomes false, false becomes true
    Task updatedTask = task.copyWith(isCompleted: newValue);
    await updateTask(updatedTask);
  }

  // Remove a task from the board permanently
  Future<void> deleteTask(Task task) async {
    try {
      await _tasksCol.doc(task.id).delete();
    } catch (error) {
      showError(error);
    }
  }

  // Delete a whole column and every task inside it at the same time.
  // A "batch" bundles multiple deletes into one network request — faster and safer.
  Future<void> deleteColumn(String columnId) async {
    try {
      WriteBatch batch = _db.batch(); // start a group of operations

      // Add every task in this column to the group delete
      for (Task task in tasks) {
        if (task.columnId == columnId) {
          batch.delete(_tasksCol.doc(task.id));
        }
      }

      // Also delete the column document itself
      batch.delete(_columnsCol.doc(columnId));

      // Now send everything to Firestore at once
      await batch.commit();
    } catch (error) {
      showError(error);
    }
  }

  // Import a list of tasks all at once (used by the AI document import feature)
  Future<void> importTasks(List<Map<String, String>> tasksData, String columnId) async {
    try {
      WriteBatch batch = _db.batch();

      for (Map<String, String> taskData in tasksData) {
        // .doc() with no argument creates a new document with a random ID
        DocumentReference docRef = _tasksCol.doc();

        Map<String, dynamic> firestoreData = {
          'title':       taskData['title'] ?? 'Untitled Task',
          'description': taskData['description'] ?? '',
          'columnId':    columnId,
          'date':        DateTime.now().toIso8601String(),
          'isCompleted': false,
        };

        batch.set(docRef, firestoreData);
      }

      await batch.commit();
    } catch (error) {
      showError(error);
    }
  }

  // Send a copy of a task to another user's board using their email address
  Future<void> assignTaskByEmail(Task task, String email) async {
    try {
      // Step 1: Find the other user's account using their email
      String? assigneeUid = await UserService.findUidByEmail(email);

      if (assigneeUid == null) {
        showError('No account found for $email');
        return; // stop here — no point continuing if they don't exist
      }

      // Step 2: Save our own email so the receiver knows who sent the task
      String ourEmail = _auth.currentUser!.email ?? '';

      // Step 3: Update our own task to remember we shared it
      await _tasksCol.doc(task.id).update({'sharedWith': email});

      // Step 4: Find the first column on the other user's board
      QuerySnapshot theirColumns = await _db
          .collection('users')
          .doc(assigneeUid)
          .collection('columns')
          .orderBy('order')
          .limit(1)
          .get();

      String targetColumnId;
      if (theirColumns.docs.isNotEmpty) {
        targetColumnId = theirColumns.docs.first.id;
      } else {
        targetColumnId = 'inbox'; // fallback column name if they have none
      }

      // Step 5: Build the task data to send over
      Map<String, dynamic> taskData = task.toJson();
      taskData.remove('id');              // the new document will get its own ID
      taskData['columnId'] = targetColumnId;
      taskData['sharedBy'] = ourEmail;    // so they know who sent it
      taskData.remove('sharedWith');      // the copy they get doesn't need this

      // Step 6: Add the task to their account in Firestore
      await _db
          .collection('users')
          .doc(assigneeUid)
          .collection('tasks')
          .add(taskData);

      // Step 7: Tell the user it worked
      Get.snackbar(
        'Task Assigned',
        'Task sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (error) {
      showError(error);
    }
  }

  // Ask the AI to write a short description for a task based on its title.
  // This is in the controller (not the widget) so the UI doesn't need to know about AIService.
  Future<String> generateTaskDescription(String title) async {
    Map<String, String> aiResult = await AIService.generateTaskDetails(title);
    String description = aiResult['description'] ?? '';
    return description;
  }

  // Show a red error message at the bottom of the screen
  void showError(Object error) {
    Get.snackbar(
      'Error',
      error.toString(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  // onClose runs automatically when the controller is destroyed (when the screen closes).
  // We MUST cancel our stream subscriptions here, otherwise they keep running in the
  // background and can cause crashes or memory leaks.
  @override
  void onClose() {
    _authSub?.cancel();    // stop watching for logout
    _tasksSub?.cancel();   // stop watching tasks
    _columnsSub?.cancel(); // stop watching columns
    super.onClose();
  }
}
