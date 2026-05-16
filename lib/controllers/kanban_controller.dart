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

  StreamSubscription<QuerySnapshot>? _tasksSub;
  StreamSubscription<QuerySnapshot>? _columnsSub;
  StreamSubscription<User?>?         _authSub;

  final RxList<Task>       tasks     = <Task>[].obs;
  final RxList<ColumnData> columns   = <ColumnData>[].obs;
  final RxBool             isLoading = true.obs;
  final RxList<String>     expandedIds  = <String>[].obs;
  final RxString           searchQuery  = ''.obs;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _db.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _columnsCol =>
      _db.collection('users').doc(_uid).collection('columns');

  List<Task> tasksFor(String columnId) {
    String query = searchQuery.value.toLowerCase().trim();
    List<Task> result = [];

    for (Task task in tasks) {
      if (task.columnId != columnId) continue;

      if (query.isNotEmpty) {
        bool titleMatches       = task.title.toLowerCase().contains(query);
        bool descriptionMatches = (task.description ?? '').toLowerCase().contains(query);
        if (!titleMatches && !descriptionMatches) continue;
      }

      result.add(task);
    }

    result.sort((Task a, Task b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });

    return result;
  }

  int overdueCountFor(String columnId) {
    DateTime now = DateTime.now();
    int count = 0;

    for (Task task in tasks) {
      if (task.columnId == columnId && !task.isCompleted) {
        if (task.duedate != null && task.duedate!.isBefore(now)) {
          count++;
        }
      }
    }

    return count;
  }

  void toggleExpanded(String taskId) {
    if (expandedIds.contains(taskId)) {
      expandedIds.remove(taskId);
    } else {
      expandedIds.add(taskId);
    }
  }

  bool isTaskExpanded(String taskId) => expandedIds.contains(taskId);

  @override
  void onInit() {
    super.onInit();

    _authSub = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // cancel streams first so they don't fire a permissions error after the token is gone
        _tasksSub?.cancel();
        _columnsSub?.cancel();
        Get.offAllNamed('/login');
      }
    });

    _columnsSub = _columnsCol.orderBy('order').snapshots().listen(
      (QuerySnapshot snap) {
        List<ColumnData> newColumns = [];

        for (QueryDocumentSnapshot doc in snap.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          newColumns.add(ColumnData.fromJson(data));
        }

        columns.value   = newColumns;
        isLoading.value = false;
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
          newTasks.add(Task.fromJson(data));
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
      await _columnsCol.add({'label': label, 'order': columns.length});
    } catch (error) {
      showError(error);
    }
  }

  Future<void> addTask(String title, String columnId) async {
    try {
      await _tasksCol.add({
        'title':       title,
        'columnId':    columnId,
        'date':        DateTime.now().toIso8601String(),
        'isCompleted': false,
      });
    } catch (error) {
      showError(error);
    }
  }

  // optimistic update: reflect the change on screen immediately, revert if the save fails
  Future<void> updateTask(Task task) async {
    int index = tasks.indexWhere((t) => t.id == task.id);
    Task? backup;

    if (index != -1) {
      backup = tasks[index];
      tasks[index] = task;
    }

    try {
      Map<String, dynamic> data = task.toJson();
      data.remove('id'); // Firestore document ID is not stored as a field
      await _tasksCol.doc(task.id).update(data);
    } catch (error) {
      if (index != -1 && backup != null) tasks[index] = backup;
      showError(error);
    }
  }

  Future<void> toggleComplete(Task task) async {
    await updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _tasksCol.doc(task.id).delete();
    } catch (error) {
      showError(error);
    }
  }

  // batch deletes all tasks in the column and the column itself in one request
  Future<void> deleteColumn(String columnId) async {
    try {
      WriteBatch batch = _db.batch();

      for (Task task in tasks) {
        if (task.columnId == columnId) {
          batch.delete(_tasksCol.doc(task.id));
        }
      }

      batch.delete(_columnsCol.doc(columnId));
      await batch.commit();
    } catch (error) {
      showError(error);
    }
  }

  Future<void> importTasks(List<Map<String, String>> tasksData, String columnId) async {
    try {
      WriteBatch batch = _db.batch();

      for (Map<String, String> taskData in tasksData) {
        DocumentReference docRef = _tasksCol.doc();
        batch.set(docRef, {
          'title':       taskData['title'] ?? 'Untitled Task',
          'description': taskData['description'] ?? '',
          'columnId':    columnId,
          'date':        DateTime.now().toIso8601String(),
          'isCompleted': false,
        });
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
      String? assigneeUid = await UserService.findUidByEmail(email);

      if (assigneeUid == null) {
        showError('No account found for $email');
        return;
      }

      String ourEmail = _auth.currentUser!.email ?? '';

      await _tasksCol.doc(task.id).update({'sharedWith': email, 'username': email});

      QuerySnapshot theirColumns = await _db
          .collection('users')
          .doc(assigneeUid)
          .collection('columns')
          .orderBy('order')
          .limit(1)
          .get();

      String targetColumnId = theirColumns.docs.isNotEmpty
          ? theirColumns.docs.first.id
          : 'inbox'; // fallback if the receiver has no columns

      Map<String, dynamic> taskData = task.toJson();
      taskData.remove('id');
      taskData.remove('sharedWith');
      taskData['columnId'] = targetColumnId;
      taskData['sharedBy'] = ourEmail;

      await _db
          .collection('users')
          .doc(assigneeUid)
          .collection('tasks')
          .add(taskData);

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

  Future<String> generateTaskDescription(String title) async {
    Map<String, String> result = await AIService.generateTaskDetails(title);
    return result['description'] ?? '';
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

  @override
  void onClose() {
    _authSub?.cancel();
    _tasksSub?.cancel();
    _columnsSub?.cancel();
    super.onClose();
  }
}
