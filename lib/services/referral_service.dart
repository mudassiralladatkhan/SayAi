import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  static final _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Generate a unique 6-char referral code ────────────────────────────────
  static String _generateCode(String uid) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random(uid.hashCode);
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ─── Get or create the user's referral code ────────────────────────────────
  static Future<String> getOrCreateCode() async {
    if (_uid == null) return '';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('referral_code');
    if (cached != null && cached.isNotEmpty) return cached;

    // Check Firestore
    final doc = await _db.collection('users').doc(_uid).get();
    if (doc.exists && doc.data()?['referral_code'] != null) {
      final code = doc.data()!['referral_code'] as String;
      await prefs.setString('referral_code', code);
      return code;
    }

    // Generate new code and save
    final code = _generateCode(_uid!);
    await _db.collection('users').doc(_uid).set({
      'referral_code': code,
      'referral_count': 0,
    }, SetOptions(merge: true));
    await prefs.setString('referral_code', code);
    return code;
  }

  // ─── Get how many people used this user's code ────────────────────────────
  static Future<int> getReferralCount() async {
    if (_uid == null) return 0;
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      return (doc.data()?['referral_count'] ?? 0) as int;
    } catch (_) {
      return 0;
    }
  }

  // ─── Get rewards earned (7 free days per referral) ────────────────────────
  static Future<int> getRewardDays() async {
    final count = await getReferralCount();
    return count * 7; // 7 free Pro days per referral
  }

  // ─── Apply a referral code entered by the user ────────────────────────────
  /// Returns a result message string.
  static Future<String> applyReferralCode(String code) async {
    if (_uid == null) return 'Please log in first.';
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return 'Please enter a referral code.';

    final prefs = await SharedPreferences.getInstance();

    // Check if this user already used a referral code
    final alreadyUsed = prefs.getBool('referral_used') ?? false;
    if (alreadyUsed) return 'Aapne already ek referral code use kar liya hai!';

    // Don't allow using your own code
    final myCode = await getOrCreateCode();
    if (cleanCode == myCode) return 'Apna khud ka code use nahi kar sakte yaar! 😄';

    try {
      // Find the owner of this referral code
      final query = await _db
          .collection('users')
          .where('referral_code', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return 'Yeh code valid nahi hai. Dobara check karo!';

      final referrerDoc = query.docs.first;
      final referrerId = referrerDoc.id;

      // Prevent the referrer from using their own code via another path
      if (referrerId == _uid) return 'Apna khud ka code use nahi kar sakte! 😄';

      // Batch update: increment referrer count + mark current user as referred
      final batch = _db.batch();

      // Increment referrer's count
      batch.update(_db.collection('users').doc(referrerId), {
        'referral_count': FieldValue.increment(1),
        'referral_reward_days': FieldValue.increment(7),
      });

      // Mark current user as having used a referral
      batch.update(_db.collection('users').doc(_uid), {
        'referred_by': referrerId,
        'referred_by_code': cleanCode,
        'referral_bonus_days': 3, // New user gets 3 bonus days
      });

      await batch.commit();

      // Save locally so we don't allow double-use
      await prefs.setBool('referral_used', true);
      await prefs.setString('referred_by_code', cleanCode);

      return 'SUCCESS: Code applied! Aapko 3 bonus days mile! 🎉\nAur ${referrerDoc.data()['user_name'] ?? 'Aapke dost'} ko 7 free Pro days!';
    } catch (e) {
      return 'Kuch gadbad ho gayi. Please try again.';
    }
  }

  // ─── Check if current user was referred ────────────────────────────────────
  static Future<bool> wasReferred() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('referral_used') ?? false;
  }

  // ─── Get the referral leaderboard (top 5 referrers) ────────────────────────
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final query = await _db
          .collection('users')
          .where('referral_count', isGreaterThan: 0)
          .orderBy('referral_count', descending: true)
          .limit(5)
          .get();

      return query.docs.map((doc) => {
        'name': doc.data()['user_name'] ?? 'Anonymous',
        'count': doc.data()['referral_count'] ?? 0,
        'isMe': doc.id == _uid,
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
