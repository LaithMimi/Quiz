import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/models/column_data.dart';
import 'package:quiz/models/subtask_data.dart';

class KanbanController extends GetxController {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _tasksSub;
  StreamSubscription<QuerySnapshot>? _columnsSub;

  final RxList<Subtask>    tasks   = <Subtask>[].obs;
  final RxList<ColumnData> columns = <ColumnData>[].obs;
  final RxBool isLoading = true.obs;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _db.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _columnsCol =>
      _db.collection('users').doc(_uid).collection('columns');

  List<Subtask> tasksFor(String columnId) =>
      tasks.where((t) => t.columnId == columnId).toList();

  @override
  void onInit() {
    super.onInit();

    _columnsSub = _columnsCol.orderBy('order').snapshots().listen(
      (snap) {
        columns.value = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ColumnData.fromJson(data);
        }).toList();
        isLoading.value = false;
      },
      onError: (e) {
        _showError(e);
        isLoading.value = false;
      },
    );

    _tasksSub = _tasksCol.snapshots().listen(
      (snap) {
        tasks.value = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Subtask.fromJson(data);
        }).toList();
      },
      onError: _showError,
    );
  }

  Future<void> addColumn(String label) async {
    try {
      await _columnsCol.add({'label': label, 'order': columns.length});
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> addTask(String title, String columnId) async {
    try {
      await _tasksCol.add({
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
      await _tasksCol.doc(task.id).update(data);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> deleteTask(Subtask task) async {
    try {
      await _tasksCol.doc(task.id).delete();
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
