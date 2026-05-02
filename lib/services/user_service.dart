import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

/// Central service for all Firestore read/write operations.
class UserService {
  static final _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'saynoteai',
  );
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Profile ───────────────────────────────────────────────────────────────

  /// Save user profile to Firestore.
  static Future<void> saveProfile({
    required String name,
    required String tone,
    required String language,
    bool? tuYaAap,
    bool? shayariEnabled,
  }) async {
    if (_uid == null) return;
    try {
      final Map<String, dynamic> data = {
        'user_name': name,
        'yog_tone': tone,
        'yog_language': language,
        'has_onboarded': true,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (tuYaAap != null) data['tu_ya_aap'] = tuYaAap;
      if (shayariEnabled != null) data['shayari_enabled'] = shayariEnabled;

      await _firestore.collection('users').doc(_uid).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Save alarm settings to Firestore.
  static Future<void> saveAlarmSettings({
    int? hour,
    int? minute,
    String? customMessage,
  }) async {
    if (_uid == null) return;
    try {
      final Map<String, dynamic> data = {};
      if (hour != null) data['alarm_hour'] = hour;
      if (minute != null) data['alarm_minute'] = minute;
      if (customMessage != null) data['custom_alarm_message'] = customMessage;
      if (data.isEmpty) return;
      await _firestore.collection('users').doc(_uid).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Load user profile from Firestore and write to SharedPreferences.
  static Future<bool> loadProfileIntoPrefs() async {
    if (_uid == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      // Profile
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
      if (data['tu_ya_aap'] != null) await prefs.setBool('tu_ya_aap', data['tu_ya_aap']);
      if (data['shayari_enabled'] != null) await prefs.setBool('shayari_enabled', data['shayari_enabled']);

      // Streak
      if (data['streak'] != null) await prefs.setInt('streak', data['streak']);
      if (data['last_open_date'] != null) await prefs.setString('last_open_date', data['last_open_date']);

      // Alarm settings
      if (data['alarm_hour'] != null) await prefs.setInt('alarm_hour', data['alarm_hour']);
      if (data['alarm_minute'] != null) await prefs.setInt('alarm_minute', data['alarm_minute']);
      if (data['custom_alarm_message'] != null) await prefs.setString('custom_alarm_message', data['custom_alarm_message']);

      // Referral
      if (data['referral_code'] != null) await prefs.setString('referral_code', data['referral_code']);
      if (data['referred_by'] != null) await prefs.setBool('referral_used', true);

      // Membership
      if (data['plan'] != null) await prefs.setString('user_plan', data['plan']);
      if (data['member_since'] != null) await prefs.setString('member_since', data['member_since'].toString());

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Streak ────────────────────────────────────────────────────────────────

  /// Call every time the app opens. Increments streak if new day.
  static Future<int> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastOpenStr = prefs.getString('last_open_date') ?? '';
    int streak = prefs.getInt('streak') ?? 0;

    if (lastOpenStr == todayStr) return streak; // Already opened today

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    if (lastOpenStr == yesterdayStr) {
      streak += 1; // Consecutive day
    } else if (lastOpenStr.isEmpty) {
      streak = 1; // First time
    } else {
      streak = 1; // Streak broken
    }

    await prefs.setInt('streak', streak);
    await prefs.setString('last_open_date', todayStr);

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

  // ─── Mood ──────────────────────────────────────────────────────────────────

  /// Save the user's last detected mood to Firestore.
  static Future<void> saveMood(String mood) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).set({
        'last_mood': mood,
        'mood_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also log each mood event in a subcollection for history
      await _firestore
          .collection('users').doc(_uid)
          .collection('mood_log')
          .add({
        'mood': mood,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
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
      final snapshot = await _firestore.collection('users').doc(_uid).collection('tasks').get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    } catch (_) {}
  }

  // ─── Diary Entries ─────────────────────────────────────────────────────────

  static Future<void> saveDiaryEntry({
    required String id,
    required String transcript,
    required String mood,
    required DateTime timestamp,
    String type = 'voice', // 'voice' or 'night_checkin'
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
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

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

  static Future<void> deleteDiaryEntry(String id) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).collection('diary').doc(id).delete();
    } catch (_) {}
  }

  static Future<void> clearAllDiary() async {
    if (_uid == null) return;
    try {
      final snapshot = await _firestore.collection('users').doc(_uid).collection('diary').get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    } catch (_) {}
  }

  // ─── Conversation History (AI Memory) ──────────────────────────────────────

  /// Save a YOG conversation exchange to Firestore for long-term memory.
  static Future<void> saveConversation({
    required String userMessage,
    required String yogReply,
    required String mood,
  }) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users').doc(_uid)
          .collection('conversations')
          .add({
        'user_message': userMessage,
        'yog_reply': yogReply,
        'mood': mood,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── Plan / Subscription ───────────────────────────────────────────────────

  static Future<void> updatePlan(String plan) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).set({
        'plan': plan,
        'plan_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<String> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_plan');
    if (cached != null) return cached;
    if (_uid == null) return 'free';
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      final plan = doc.data()?['plan'] ?? 'free';
      await prefs.setString('user_plan', plan);
      return plan;
    } catch (_) {
      return 'free';
    }
  }
}
