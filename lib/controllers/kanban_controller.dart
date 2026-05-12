import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/models/subtask_data.dart';

class KanbanController extends GetxController {
  final _collection = FirebaseFirestore.instance.collection('tasks');
  StreamSubscription<QuerySnapshot>? _subscription;

  final RxList<Subtask> tasks = <Subtask>[].obs;
  final RxBool isLoading = true.obs;

  static const List<String> statuses = ['todo', 'inProgress', 'done'];
  static const Map<String, String> columnLabels = {
    'todo': 'To Do',
    'inProgress': 'In Progress',
    'done': 'Done',
  };

  List<Subtask> tasksFor(String status) =>
      tasks.where((t) => t.status == status).toList();

  @override
  void onInit() {
    super.onInit();
    _subscription = _collection.snapshots().listen(
      (snapshot) {
        tasks.value = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Subtask.fromJson(data);
        }).toList();
        isLoading.value = false;
      },
      onError: (e) {
        _showError(e);
        isLoading.value = false;
      },
    );
  }

  Future<void> addTask(String title) async {
    try {
      await _collection.add({
        'title': title,
        'status': 'todo',
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> moveForward(Subtask task) async {
    final idx = statuses.indexOf(task.status);
    if (idx >= statuses.length - 1) return;
    await _updateStatus(task, statuses[idx + 1]);
  }

  Future<void> moveBack(Subtask task) async {
    final idx = statuses.indexOf(task.status);
    if (idx <= 0) return;
    await _updateStatus(task, statuses[idx - 1]);
  }

  Future<void> deleteTask(Subtask task) async {
    try {
      await _collection.doc(task.id).delete();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _updateStatus(Subtask task, String newStatus) async {
    try {
      await _collection.doc(task.id).update({'status': newStatus});
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
    _subscription?.cancel();
    super.onClose();
  }
}
