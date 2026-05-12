import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/subtask_data.dart';

class KanbanController extends GetxController {
  final _db   = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<DatabaseEvent>? _tasksSub;
  StreamSubscription<DatabaseEvent>? _columnsSub;

  final RxList<Subtask>    tasks   = <Subtask>[].obs;
  final RxList<ColumnData> columns = <ColumnData>[].obs;
  final RxBool isLoading = true.obs;

  String get _uid => _auth.currentUser!.uid;

  DatabaseReference get _tasksRef   => _db.ref('users/$_uid/tasks');
  DatabaseReference get _columnsRef => _db.ref('users/$_uid/columns');

  List<Subtask> tasksFor(String columnId) =>
      tasks.where((t) => t.columnId == columnId).toList();

  @override
  void onInit() {
    super.onInit();

    _columnsSub = _columnsRef.orderByChild('order').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null) {
          columns.value = [];
        } else {
          final map = Map<String, dynamic>.from(data as Map);
          columns.value = map.entries.map((e) {
            final col = Map<String, dynamic>.from(e.value as Map);
            col['id'] = e.key;
            return ColumnData.fromJson(col);
          }).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
        }
        isLoading.value = false;
      },
      onError: (e) {
        _showError(e);
        isLoading.value = false;
      },
    );

    _tasksSub = _tasksRef.onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null) {
          tasks.value = [];
        } else {
          final map = Map<String, dynamic>.from(data as Map);
          tasks.value = map.entries.map((e) {
            final task = Map<String, dynamic>.from(e.value as Map);
            task['id'] = e.key;
            return Subtask.fromJson(task);
          }).toList();
        }
      },
      onError: _showError,
    );
  }

  Future<void> addColumn(String label) async {
    try {
      await _columnsRef.push().set({'label': label, 'order': columns.length});
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> addTask(String title, String columnId) async {
    try {
      await _tasksRef.push().set({
        'title': title,
        'columnId': columnId,
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> updateTask(Subtask task) async {
    try {
      final data = task.toJson()..remove('id');
      await _tasksRef.child(task.id).update(data);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> deleteTask(Subtask task) async {
    try {
      await _tasksRef.child(task.id).remove();
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
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
