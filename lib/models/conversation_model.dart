import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<dynamic> messages;
  final DateTime timestamp;
  final String mood;
  final String summary;

  ConversationModel({
    required this.id,
    required this.messages,
    required this.timestamp,
    this.mood = 'neutral',
    this.summary = '',
  });

  factory ConversationModel.fromMap(Map<String, dynamic> data, String id) {
    return ConversationModel(
      id: id,
      messages: data['messages'] ?? [],
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      mood: data['mood'] ?? 'neutral',
      summary: data['summary'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messages': messages,
      'timestamp': Timestamp.fromDate(timestamp),
      'mood': mood,
      'summary': summary,
    };
  }
}
