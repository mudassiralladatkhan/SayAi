import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap here if needed
      },
    );
    tz.initializeTimeZones();
    _initialized = true;
    debugPrint('NotificationService: Initialized.');
  }

  Future<void> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Show an immediate notification when a task is added by YOG
  Future<void> showTaskAddedNotification(TaskModel task) async {
    const androidDetails = AndroidNotificationDetails(
      'yog_tasks_channel',
      'YOG Task Reminders',
      channelDescription: 'Notifications for your scheduled tasks from YOG',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF7C3AED),
      playSound: true,
      enableVibration: true,
    );

    final id = task.id.hashCode.abs() % 100000;

    // v21: all named parameters
    await _plugin.show(
      id: id,
      title: '✅ Task Added: ${task.title}',
      body: 'YOG ne schedule kar diya! ${task.duration}',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
    debugPrint('NotificationService: Showed notification for ${task.title}');
  }

  /// Cancel a specific task's notification by its ID
  Future<void> cancelTaskNotification(String taskId) async {
    // v21: named parameter is 'id:'
    await _plugin.cancel(id: taskId.hashCode.abs() % 100000);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Schedule the daily Wake-up Alarm
  Future<void> scheduleDailyAlarm(TimeOfDay time) async {
    await _plugin.cancel(id: 99999); // Cancel existing alarm if any

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    // If time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'yog_alarm_channel',
      'Wake-up Alarm',
      channelDescription: 'Daily morning alarm from YOG',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF7C3AED),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    await _plugin.zonedSchedule(
      id: 99999, // id
      title: '⏰ Utho Yaar!', // title
      body: 'YOG is waiting for your morning check-in.', // body
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at this time
    );

    debugPrint('NotificationService: Daily alarm scheduled for \${time.hour}:\${time.minute}');
  }
}
