import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/task_data.dart';
import 'package:quiz/services/user_service.dart';

class KanbanController extends GetxController {
  // Firebase instances
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream subscriptions to listen for real-time changes from Firestore
  StreamSubscription<QuerySnapshot>? _tasksSub;
  StreamSubscription<QuerySnapshot>? _columnsSub;

  // Observable lists — the UI will automatically rebuild when these change
  final RxList<Task> tasks = <Task>[].obs;
  final RxList<ColumnData> columns = <ColumnData>[].obs;
  final RxBool isLoading = true.obs;

  // Get the currently logged-in user's ID
  String get _uid {
    return _auth.currentUser!.uid;
  }

  // Reference to the current user's tasks collection in Firestore
  CollectionReference<Map<String, dynamic>> get _tasksCol {
    return _db.collection('users').doc(_uid).collection('tasks');
  }

  // Reference to the current user's columns collection in Firestore
  CollectionReference<Map<String, dynamic>> get _columnsCol {
    return _db.collection('users').doc(_uid).collection('columns');
  }

  // Return only the tasks that belong to a specific column
  List<Task> tasksFor(String columnId) {
    List<Task> columnTasks = [];

    for (Task task in tasks) {
      if (task.columnId == columnId) {
        columnTasks.add(task);
      }
    }

    return columnTasks;
  }

  @override
  void onInit() {
    super.onInit();

    // Listen to columns in Firestore and update the list when they change
    _columnsSub = _columnsCol.orderBy('order').snapshots().listen(
      (QuerySnapshot snap) {
        List<ColumnData> newColumns = [];

        for (QueryDocumentSnapshot doc in snap.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          ColumnData column = ColumnData.fromJson(data);
          newColumns.add(column);
        }

        columns.value = newColumns;
        isLoading.value = false;
      },
      onError: (Object e) {
        showError(e);
        isLoading.value = false;
      },
    );

    // Listen to tasks in Firestore and update the list when they change
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

  // Add a new column to the board
  Future<void> addColumn(String label) async {
    try {
      Map<String, dynamic> columnData = {
        'label': label,
        'order': columns.length,
      };

      await _columnsCol.add(columnData);
    } catch (e) {
      showError(e);
    }
  }

  // Add a new task to a column
  Future<void> addTask(String title, String columnId) async {
    try {
      Map<String, dynamic> taskData = {
        'title': title,
        'columnId': columnId,
        'date': DateTime.now().toIso8601String(),
      };

      await _tasksCol.add(taskData);
    } catch (e) {
      showError(e);
    }
  }

  // Save changes to an existing task
  Future<void> updateTask(Task task) async {
    try {
      Map<String, dynamic> data = task.toJson();
      data.remove('id'); // The Firestore document ID is not stored as a field

      await _tasksCol.doc(task.id).update(data);
    } catch (e) {
      showError(e);
    }
  }

  // Delete a task from Firestore
  Future<void> deleteTask(Task task) async {
    try {
      await _tasksCol.doc(task.id).delete();
    } catch (e) {
      showError(e);
    }
  }

  // Delete a column and all the tasks inside it
  Future<void> deleteColumn(String columnId) async {
    try {
      WriteBatch batch = _db.batch();

      // Add each task in this column to the batch delete
      for (Task task in tasks) {
        if (task.columnId == columnId) {
          batch.delete(_tasksCol.doc(task.id));
        }
      }

      // Also delete the column document itself
      batch.delete(_columnsCol.doc(columnId));

      await batch.commit();
    } catch (e) {
      showError(e);
    }
  }

  // Import a list of tasks into a specific column all at once
  Future<void> importTasks(List<Map<String, String>> tasksData, String columnId) async {
    try {
      WriteBatch batch = _db.batch();

      for (Map<String, String> taskData in tasksData) {
        DocumentReference docRef = _tasksCol.doc();

        Map<String, dynamic> firestoreData = {
          'title': taskData['title'] ?? 'Untitled Task',
          'columnId': columnId,
          'date': DateTime.now().toIso8601String(),
        };

        batch.set(docRef, firestoreData);
      }

      await batch.commit();
    } catch (e) {
      showError(e);
    }
  }

  // Send a copy of a task to another user's board using their email address
  Future<void> assignTaskByEmail(Task task, String email) async {
    try {
      // Step 1: Look up the other user's UID using their email
      String? assigneeUid = await UserService.findUidByEmail(email);

      if (assigneeUid == null) {
        showError('No account found for $email');
        return;
      }

      // Step 2: Get the current user's email to record who sent the task
      String ownerEmail = _auth.currentUser!.email ?? '';

      // Step 3: Update our own task to record who we sent it to
      await _tasksCol.doc(task.id).update({'sharedWith': email});

      // Step 4: Find the first column on the assignee's board to place the task
      QuerySnapshot assigneeColumnsSnap = await _db
          .collection('users')
          .doc(assigneeUid)
          .collection('columns')
          .orderBy('order')
          .limit(1)
          .get();

      String targetColumnId;
      if (assigneeColumnsSnap.docs.isNotEmpty) {
        targetColumnId = assigneeColumnsSnap.docs.first.id;
      } else {
        targetColumnId = 'inbox';
      }

      // Step 5: Build the task data to send to the assignee
      Map<String, dynamic> taskData = task.toJson();
      taskData.remove('id');
      taskData['columnId'] = targetColumnId;
      taskData['sharedBy'] = ownerEmail;
      taskData.remove('sharedWith');

      // Step 6: Add the task to the assignee's tasks collection
      await _db
          .collection('users')
          .doc(assigneeUid)
          .collection('tasks')
          .add(taskData);

      // Step 7: Show a success message
      Get.snackbar(
        'Task Assigned',
        'Task sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      showError(e);
    }
  }

  // Show an error message at the bottom of the screen
  void showError(Object e) {
    Get.snackbar(
      'Error',
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    _tasksSub?.cancel();
    _columnsSub?.cancel();
    super.onClose();
  }
}
