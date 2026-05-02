import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

/// Central service for all Firestore read/write operations.
class UserService {
  static final _firestore = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Profile ───────────────────────────────────────────────────────────────

  /// Save user profile to Firestore.
  static Future<void> saveProfile({
    required String name,
    required String tone,
    required String language,
  }) async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).set({
      'user_name': name,
      'yog_tone': tone,
      'yog_language': language,
      'has_onboarded': true,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Load user profile from Firestore and write to SharedPreferences.
  /// Returns true if data was found.
  static Future<bool> loadProfileIntoPrefs() async {
    if (_uid == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      if (data['user_name'] != null) {
        await prefs.setString('user_name', data['user_name']);
      }
      if (data['yog_tone'] != null) {
        await prefs.setString('yog_tone', data['yog_tone']);
        await prefs.setString('user_tone', data['yog_tone']); // settings uses user_tone
      }
      if (data['yog_language'] != null) {
        await prefs.setString('yog_language', data['yog_language']);
        await prefs.setString('user_language', data['yog_language']);
      }
      if (data['has_onboarded'] == true) {
        await prefs.setBool('has_onboarded', true);
      }
      // Optional extra fields
      if (data['streak'] != null) {
        await prefs.setInt('streak', data['streak']);
      }
      if (data['tu_ya_aap'] != null) {
        await prefs.setBool('tu_ya_aap', data['tu_ya_aap']);
      }
      if (data['shayari_enabled'] != null) {
        await prefs.setBool('shayari_enabled', data['shayari_enabled']);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Tasks ─────────────────────────────────────────────────────────────────

  /// Push a single task to Firestore.
  static Future<void> addTask(TaskModel task) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('tasks')
          .doc(task.id)
          .set(task.toJson());
    } catch (e) {
      // Non-critical: local save is already done
    }
  }

  /// Update completion status of a task.
  static Future<void> updateTaskCompletion(String taskId, bool completed) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('tasks')
          .doc(taskId)
          .update({'completed': completed});
    } catch (e) {
      // Non-critical
    }
  }

  /// Delete a task from Firestore.
  static Future<void> deleteTask(String taskId) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      // Non-critical
    }
  }

  /// Fetch all tasks from Firestore and return as list.
  static Future<List<TaskModel>> fetchTasks() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('tasks')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete ALL tasks from Firestore (for Clear All Data).
  static Future<void> clearAllTasks() async {
    if (_uid == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('tasks')
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Non-critical
    }
  }
}
