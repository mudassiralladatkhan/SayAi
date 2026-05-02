import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';

/// Legacy service — core Firestore operations now handled by UserService.
/// Kept for any remaining usage in the codebase.
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<List<TaskModel>> getTasks(String userId, String dateStr) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('date', isEqualTo: dateStr)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    });
  }

  Future<void> addTask(String userId, TaskModel task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toJson());
  }

  Future<void> updateTask(String userId, TaskModel task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .update(task.toJson());
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Future<void> updateUsage(String userId, String type, int value) async {
    await _firestore.collection('users').doc(userId).collection('usage').doc('current').set({
      type: FieldValue.increment(value),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
