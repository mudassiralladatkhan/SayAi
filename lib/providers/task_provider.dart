import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../services/user_service.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  static const _storageKey = 'yog_tasks';

  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  List<TaskModel> get todayTasks {
    final today = DateTime.now();
    return _tasks.where((t) {
      if (t.time == null) return true;
      return t.time!.day == today.day &&
          t.time!.month == today.month &&
          t.time!.year == today.year;
    }).toList();
  }

  int get completedCount => _tasks.where((t) => t.completed).length;
  int get pendingCount => _tasks.where((t) => !t.completed).length;

  /// Load tasks: first try Firestore (cloud), fallback to local SharedPreferences.
  Future<void> loadTasks() async {
    // Try loading from Firestore first
    final cloudTasks = await UserService.fetchTasks();
    if (cloudTasks.isNotEmpty) {
      _tasks = cloudTasks;
      notifyListeners();
      // Also update local cache
      await _saveLocalTasks();
      return;
    }

    // Fallback to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> jsonList = jsonDecode(raw);
        _tasks = jsonList.map((j) => TaskModel.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading local tasks: $e');
    }
  }

  Future<void> _saveLocalTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _tasks.map((t) => t.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving local tasks: $e');
    }
  }

  Future<void> addTask(TaskModel task) async {
    _tasks.insert(0, task);
    notifyListeners();
    await _saveLocalTasks();
    // Sync to Firestore (non-blocking)
    UserService.addTask(task);
  }

  Future<void> addTasks(List<TaskModel> newTasks) async {
    _tasks.insertAll(0, newTasks);
    notifyListeners();
    await _saveLocalTasks();
    // Sync all new tasks to Firestore
    for (final t in newTasks) {
      UserService.addTask(t);
    }
  }

  Future<void> toggleComplete(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(completed: !_tasks[idx].completed);
      notifyListeners();
      await _saveLocalTasks();
      // Sync to Firestore
      UserService.updateTaskCompletion(taskId, _tasks[idx].completed);
    }
  }

  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _saveLocalTasks();
    // Sync deletion to Firestore
    UserService.deleteTask(taskId);
  }

  Future<void> clearAll() async {
    _tasks.clear();
    notifyListeners();
    await _saveLocalTasks();
    // Clear all tasks in Firestore
    UserService.clearAllTasks();
  }

  /// Call this on logout — clears in-memory tasks only (does NOT delete from Firestore).
  void clearForLogout() {
    _tasks.clear();
    notifyListeners();
  }
}
