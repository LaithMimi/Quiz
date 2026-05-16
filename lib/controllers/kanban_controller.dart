import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/services/ai_service.dart';
import 'package:quiz/services/user_service.dart';


class KanbanController extends GetxController {
  final FirebaseFirestore _db   = FirebaseFirestore.instance; 
  final FirebaseAuth      _auth = FirebaseAuth.instance;      

  // "Subscriptions" are like listeners, they watch for changes in Firestore
  // and run code automatically when something changes.
  // We stored them here so we can cancel them when the screen closes...
  StreamSubscription<QuerySnapshot>? _tasksSub;
  StreamSubscription<QuerySnapshot>? _columnsSub;
  StreamSubscription<User?>? _authSub; // watches if the user logs out

  // any widget wrapped in Obx() will automatically rebuild, if any of these variables change:
  final RxList<Task> tasks = <Task>[].obs;
  final RxList<ColumnData> columns = <ColumnData>[].obs;
  final RxBool isLoading = true.obs; // true while we wait for first data

  // store task IDs here when their card is open (expanded).
  // Using RxList makes the UI react when we open or close a card.
  final RxList<String> expandedIds = <String>[].obs;

  final RxString searchQuery = ''.obs;

  // We use this to find the right place in Firestore for this user's data.
  String get _uid {
    return _auth.currentUser!.uid;
  }

  CollectionReference<Map<String, dynamic>> get _tasksCol {
    return _db.collection('users').doc(_uid).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>> get _columnsCol {
    return _db.collection('users').doc(_uid).collection('columns');
  }

  // Returns a filtered and sorted list of tasks for one column.
  List<Task> tasksFor(String columnId) {
    String query = searchQuery.value.toLowerCase().trim();

    List<Task> result = [];

    for (Task task in tasks) {
      if (task.columnId != columnId) {
        continue; 
      }

      // if the user typed something in the search bar, only keep matching tasks
      if (query.isNotEmpty) {
        bool titleMatches = task.title.toLowerCase().contains(query);
        bool descriptionMatches = (task.description ?? '').toLowerCase().contains(query);

        // If the task doesn't match at all, skip it
        if (titleMatches == false && descriptionMatches == false) {
          continue;
        }
      }

      result.add(task);
    }

    // sort: completed tasks sink to the bottom of the column.
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

  // used to show the red "N overdue" badge in the column header.
  int overdueCountFor(String columnId) {
    DateTime rightNow = DateTime.now();
    int count = 0;

    for (Task task in tasks) {
      if (task.columnId == columnId && task.isCompleted == false) {
        if (task.duedate != null) { 
          if (task.duedate!.isBefore(rightNow)) {  // isBefore() returns true if the due date is earlier than right now
            count = count + 1;
          }
        }
      }
    }
    return count;
  }

  void toggleExpanded(String taskId) {
    bool cardIsCurrentlyOpen = expandedIds.contains(taskId);

    if (cardIsCurrentlyOpen) {
      expandedIds.remove(taskId); // close it
    } else {
      expandedIds.add(taskId);    // open it
    }
  }

  //returns true if the card for this task is currently showing its details.
  bool isTaskExpanded(String taskId) {
    return expandedIds.contains(taskId);
  }

  // onInit runs automatically when the controller is first created.
  @override
  void onInit() {
    super.onInit();

    // watch for the user logging out.. authStateChanges() fires every time the login state changes.
    // if "user" is null, that means nobody is logged in anymore.
    _authSub = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _tasksSub?.cancel();
        _columnsSub?.cancel();
        Get.offAllNamed('/login');
      }
    });

    // listen to the columns collection. When columns change in Firestore,
    _columnsSub = _columnsCol.orderBy('order').snapshots().listen(
      (QuerySnapshot snap) {
        List<ColumnData> newColumns = [];
        for (QueryDocumentSnapshot doc in snap.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // we need the document ID to know which column is which and to update/delete them later
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

  Future<void> renameColumn(String columnId, String newLabel) async {
    try {
      await _columnsCol.doc(columnId).update({'label': newLabel});
    } catch (error) {
      showError(error);
    }
  }

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

  Future<void> toggleComplete(Task task) async {
    bool newValue = !task.isCompleted; // flip it: true becomes false, false becomes true
    Task updatedTask = task.copyWith(isCompleted: newValue);
    await updateTask(updatedTask);
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _tasksCol.doc(task.id).delete();
    } catch (error) {
      showError(error);
    }
  }

  // A "batch" bundles multiple deletes into one network request (faster and safer).
  Future<void> deleteColumn(String columnId) async {
    try {
      WriteBatch batch = _db.batch(); // start a group of operations

      //add every task in this column to the group delete
      for (Task task in tasks) {
        if (task.columnId == columnId) {
          batch.delete(_tasksCol.doc(task.id));
        }
      }
      batch.delete(_columnsCol.doc(columnId));

      //send everything to Firestore at once
      await batch.commit();
    } catch (error) {
      showError(error);
    }
  }

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

  Future<void> assignTaskByEmail(Task task, String email) async {
    if (task.sharedBy != null) {
      showError('Received tasks cannot be reassigned.');
      return;
    }

    try {
      // Step 1: Find the other user's account using their email
      String? assigneeUid = await UserService.findUidByEmail(email);

      if (assigneeUid == null) {
        showError('No account found for $email');
        return; // stop here — no point continuing if they don't exist
      }

      // Step 2: Save our own email so the receiver knows who sent the task
      String ourEmail = _auth.currentUser!.email ?? '';

      // Step 3: Update our own task to remember we shared it and show the assignee
      await _tasksCol.doc(task.id).update({'sharedWith': email, 'username': email});

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
  Future<String> generateTaskDescription(String title) async {
    Map<String, String> aiResult = await AIService.generateTaskDetails(title);
    String description = aiResult['description'] ?? '';
    return description;
  }

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
  @override
  void onClose() {
    _authSub?.cancel();    // stop watching for logout
    _tasksSub?.cancel();   // stop watching tasks
    _columnsSub?.cancel(); // stop watching columns
    super.onClose();
  }
}
