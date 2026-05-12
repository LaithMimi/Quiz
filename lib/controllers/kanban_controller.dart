import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/models/task.dart';
import 'package:quiz/services/api_client.dart';

class KanbanController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  final RxList<Task> tasks = <Task>[].obs;
  final RxBool isLoading = false.obs;

  static const List<String> statuses = ['todo', 'inProgress', 'done'];
  static const Map<String, String> columnLabels = {
    'todo': 'To Do',
    'inProgress': 'In Progress',
    'done': 'Done',
  };

  List<Task> tasksFor(String status) =>
      tasks.where((t) => t.status == status).toList();

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    isLoading.value = true;
    try {
      final data = await _apiClient.getTasks();
      tasks.value =
          data.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTask(String title) async {
    try {
      final data = await _apiClient.createTask(title);
      tasks.add(Task.fromJson(data));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> moveForward(Task task) async {
    final idx = statuses.indexOf(task.status);
    if (idx >= statuses.length - 1) return;
    await _updateStatus(task, statuses[idx + 1]);
  }

  Future<void> moveBack(Task task) async {
    final idx = statuses.indexOf(task.status);
    if (idx <= 0) return;
    await _updateStatus(task, statuses[idx - 1]);
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _apiClient.deleteTask(task.id);
      tasks.removeWhere((t) => t.id == task.id);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _updateStatus(Task task, String newStatus) async {
    try {
      await _apiClient.updateTask(task.id, newStatus);
      final idx = tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) tasks[idx] = task.copyWith(status: newStatus);
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
    _apiClient.close();
    super.onClose();
  }
}
