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
    try {
      await _firestore.collection('users').doc(_uid).set({
        'user_name': name,
        'yog_tone': tone,
        'yog_language': language,
        'has_onboarded': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Non-critical
    }
  }

  /// Load user profile from Firestore and write to SharedPreferences.
  static Future<bool> loadProfileIntoPrefs() async {
    if (_uid == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      if (data['user_name'] != null) await prefs.setString('user_name', data['user_name']);
      if (data['yog_tone'] != null) {
        await prefs.setString('yog_tone', data['yog_tone']);
        await prefs.setString('user_tone', data['yog_tone']);
      }
      if (data['yog_language'] != null) {
        await prefs.setString('yog_language', data['yog_language']);
        await prefs.setString('user_language', data['yog_language']);
      }
      if (data['has_onboarded'] == true) await prefs.setBool('has_onboarded', true);
      if (data['streak'] != null) await prefs.setInt('streak', data['streak']);
      if (data['tu_ya_aap'] != null) await prefs.setBool('tu_ya_aap', data['tu_ya_aap']);
      if (data['shayari_enabled'] != null) await prefs.setBool('shayari_enabled', data['shayari_enabled']);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Streak ────────────────────────────────────────────────────────────────

  /// Call this every time the app is opened.
  /// Increments streak if the user hasn't opened the app today yet.
  static Future<int> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastOpenStr = prefs.getString('last_open_date') ?? '';
    int streak = prefs.getInt('streak') ?? 0;

    if (lastOpenStr == todayStr) {
      // Already opened today — no change
      return streak;
    }

    // Check if yesterday was the last open (consecutive day)
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    if (lastOpenStr == yesterdayStr) {
      // Consecutive day — increment streak
      streak += 1;
    } else if (lastOpenStr.isEmpty) {
      // First time ever
      streak = 1;
    } else {
      // Streak broken — reset to 1
      streak = 1;
    }

    await prefs.setInt('streak', streak);
    await prefs.setString('last_open_date', todayStr);

    // Sync to Firestore
    if (_uid != null) {
      try {
        await _firestore.collection('users').doc(_uid).set({
          'streak': streak,
          'last_open_date': todayStr,
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    return streak;
  }

  // ─── Tasks ─────────────────────────────────────────────────────────────────

  static Future<void> addTask(TaskModel task) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users').doc(_uid)
          .collection('tasks').doc(task.id)
          .set(task.toJson());
    } catch (_) {}
  }

  static Future<void> updateTaskCompletion(String taskId, bool completed) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users').doc(_uid)
          .collection('tasks').doc(taskId)
          .update({'completed': completed});
    } catch (_) {}
  }

  static Future<void> deleteTask(String taskId) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users').doc(_uid)
          .collection('tasks').doc(taskId)
          .delete();
    } catch (_) {}
  }

  static Future<List<TaskModel>> fetchTasks() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users').doc(_uid)
          .collection('tasks')
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearAllTasks() async {
    if (_uid == null) return;
    try {
      final snapshot = await _firestore
          .collection('users').doc(_uid)
          .collection('tasks').get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    } catch (_) {}
  }

  // ─── Diary Entries ─────────────────────────────────────────────────────────

  /// Save a diary entry to Firestore.
  static Future<void> saveDiaryEntry({
    required String id,
    required String transcript,
    required String mood,
    required DateTime timestamp,
  }) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users').doc(_uid)
          .collection('diary').doc(id)
          .set({
        'id': id,
        'transcript': transcript,
        'mood': mood,
        'timestamp': timestamp.toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Fetch all diary entries from Firestore.
  static Future<List<Map<String, dynamic>>> fetchDiaryEntries() async {
    if (_uid == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users').doc(_uid)
          .collection('diary')
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete a diary entry from Firestore.
  static Future<void> deleteDiaryEntry(String id) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users').doc(_uid)
          .collection('diary').doc(id)
          .delete();
    } catch (_) {}
  }

  /// Clear all diary entries.
  static Future<void> clearAllDiary() async {
    if (_uid == null) return;
    try {
      final snapshot = await _firestore
          .collection('users').doc(_uid)
          .collection('diary').get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    } catch (_) {}
  }
}
