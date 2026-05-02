class TaskModel {
  final String id;
  final String title;
  final DateTime? time;
  final String duration;
  final String category;
  final bool completed;
  final String date;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.time,
    this.duration = '30 min',
    this.category = 'general',
    this.completed = false,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TaskModel.fromJson(Map<String, dynamic> data) {
    return TaskModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      time: data['time'] != null ? DateTime.tryParse(data['time']) : null,
      duration: data['duration'] ?? '30 min',
      category: data['category'] ?? 'general',
      completed: data['completed'] ?? false,
      date: data['date'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time?.toIso8601String(),
      'duration': duration,
      'category': category,
      'completed': completed,
      'date': date,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    DateTime? time,
    String? duration,
    String? category,
    bool? completed,
    String? date,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      completed: completed ?? this.completed,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
