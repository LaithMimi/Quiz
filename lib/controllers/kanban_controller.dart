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
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _tasksSub;
  StreamSubscription<QuerySnapshot>? _columnsSub;
  StreamSubscription<User?>? _authSub;

  final RxList<Task> tasks = <Task>[].obs;
  final RxList<ColumnData> columns = <ColumnData>[].obs;
  final RxBool isLoading = true.obs;

  // IDs of expanded task cards — persists across Obx rebuilds
  final RxList<String> expandedIds = <String>[].obs;

  // Live search query — columns filter their task lists reactively
  final RxString searchQuery = ''.obs;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _db.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _columnsCol =>
      _db.collection('users').doc(_uid).collection('columns');

  // Return tasks for a column, filtered by search and sorted (incomplete first)
  List<Task> tasksFor(String columnId) {
    String query = searchQuery.value.toLowerCase().trim();
    List<Task> result = [];

    for (Task task in tasks) {
      if (task.columnId != columnId) continue;
      if (query.isNotEmpty) {
        bool titleMatch = task.title.toLowerCase().contains(query);
        bool descMatch = (task.description ?? '').toLowerCase().contains(query);
        if (!titleMatch && !descMatch) continue;
      }
      result.add(task);
    }

    result.sort((Task a, Task b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });

    return result;
  }

  // Count non-completed overdue tasks in a column for the header badge
  int overdueCountFor(String columnId) {
    DateTime now = DateTime.now();
    int count = 0;
    for (Task task in tasks) {
      if (task.columnId == columnId && !task.isCompleted) {
        DateTime? due = task.duedate;
        if (due != null && due.isBefore(now)) count++;
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

    // Auth guard: redirect to login if session ends
    _authSub = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
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
        columns.value = newColumns;
        isLoading.value = false;
      },
      onError: (Object e) {
        showError(e);
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

  Future<void> addColumn(String label) async {
    try {
      await _columnsCol.add({'label': label, 'order': columns.length});
    } catch (e) {
      showError(e);
    }
  }

  Future<void> addTask(String title, String columnId) async {
    try {
      await _tasksCol.add({
        'title': title,
        'columnId': columnId,
        'date': DateTime.now().toIso8601String(),
        'isCompleted': false,
      });
    } catch (e) {
      showError(e);
    }
  }

  // Optimistic update: apply locally first, revert if Firestore write fails
  Future<void> updateTask(Task task) async {
    int index = tasks.indexWhere((Task t) => t.id == task.id);
    Task? previous = index != -1 ? tasks[index] : null;
    if (index != -1) tasks[index] = task;

    try {
      Map<String, dynamic> data = task.toJson();
      data.remove('id');
      await _tasksCol.doc(task.id).update(data);
    } catch (e) {
      if (index != -1 && previous != null) tasks[index] = previous;
      showError(e);
    }
  }

  Future<void> toggleComplete(Task task) async {
    await updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _tasksCol.doc(task.id).delete();
    } catch (e) {
      showError(e);
    }
  }

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
    } catch (e) {
      showError(e);
    }
  }

  Future<void> importTasks(List<Map<String, String>> tasksData, String columnId) async {
    try {
      WriteBatch batch = _db.batch();
      for (Map<String, String> taskData in tasksData) {
        DocumentReference docRef = _tasksCol.doc();
        batch.set(docRef, {
          'title': taskData['title'] ?? 'Untitled Task',
          'description': taskData['description'] ?? '',
          'columnId': columnId,
          'date': DateTime.now().toIso8601String(),
          'isCompleted': false,
        });
      }
      await batch.commit();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> assignTaskByEmail(Task task, String email) async {
    try {
      String? assigneeUid = await UserService.findUidByEmail(email);
      if (assigneeUid == null) {
        showError('No account found for $email');
        return;
      }

      String ownerEmail = _auth.currentUser!.email ?? '';
      await _tasksCol.doc(task.id).update({'sharedWith': email});

      QuerySnapshot assigneeColumnsSnap = await _db
          .collection('users')
          .doc(assigneeUid)
          .collection('columns')
          .orderBy('order')
          .limit(1)
          .get();

      String targetColumnId = assigneeColumnsSnap.docs.isNotEmpty
          ? assigneeColumnsSnap.docs.first.id
          : 'inbox';

      Map<String, dynamic> taskData = task.toJson();
      taskData.remove('id');
      taskData['columnId'] = targetColumnId;
      taskData['sharedBy'] = ownerEmail;
      taskData.remove('sharedWith');

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
    } catch (e) {
      showError(e);
    }
  }

  Future<String> generateTaskDescription(String title) async {
    Map<String, String> result = await AIService.generateTaskDetails(title);
    return result['description'] ?? '';
  }

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
    _authSub?.cancel();
    _tasksSub?.cancel();
    _columnsSub?.cancel();
    super.onClose();
  }
}
