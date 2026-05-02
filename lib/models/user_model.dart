import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String naam;
  final String plan;
  final String language;
  final String tone;
  final bool tuYaAap;
  final int streak;
  final DateTime? streakLastDate;
  final double consistency;
  final int level;
  final DateTime? joinDate;
  final String lastMood;
  final bool biometricEnabled;
  final bool dataOptIn;
  final String? referralCode;
  final int referralCount;
  final String? referredBy;

  UserModel({
    required this.id,
    required this.naam,
    this.plan = 'free',
    this.language = 'hinglish',
    this.tone = 'yaar',
    this.tuYaAap = true,
    this.streak = 0,
    this.streakLastDate,
    this.consistency = 0.0,
    this.level = 1,
    this.joinDate,
    this.lastMood = 'neutral',
    this.biometricEnabled = false,
    this.dataOptIn = false,
    this.referralCode,
    this.referralCount = 0,
    this.referredBy,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      naam: data['naam'] ?? '',
      plan: data['plan'] ?? 'free',
      language: data['language'] ?? 'hinglish',
      tone: data['tone'] ?? 'yaar',
      tuYaAap: data['tuYaAap'] ?? true,
      streak: data['streak'] ?? 0,
      streakLastDate: data['streakLastDate'] != null 
          ? (data['streakLastDate'] as Timestamp).toDate() 
          : null,
      consistency: (data['consistency'] ?? 0.0).toDouble(),
      level: data['level'] ?? 1,
      joinDate: data['joinDate'] != null 
          ? (data['joinDate'] as Timestamp).toDate() 
          : null,
      lastMood: data['lastMood'] ?? 'neutral',
      biometricEnabled: data['biometricEnabled'] ?? false,
      dataOptIn: data['dataOptIn'] ?? false,
      referralCode: data['referralCode'],
      referralCount: data['referralCount'] ?? 0,
      referredBy: data['referredBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'naam': naam,
      'plan': plan,
      'language': language,
      'tone': tone,
      'tuYaAap': tuYaAap,
      'streak': streak,
      'streakLastDate': streakLastDate != null ? Timestamp.fromDate(streakLastDate!) : null,
      'consistency': consistency,
      'level': level,
      'joinDate': joinDate != null ? Timestamp.fromDate(joinDate!) : null,
      'lastMood': lastMood,
      'biometricEnabled': biometricEnabled,
      'dataOptIn': dataOptIn,
      'referralCode': referralCode,
      'referralCount': referralCount,
      'referredBy': referredBy,
    };
  }
}
