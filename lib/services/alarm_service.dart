import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmService {
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleAlarm(int id, DateTime dateTime) async {
    await AndroidAlarmManager.oneShotAt(
      dateTime,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  static Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
}

/// Global top-level callback — fires when the alarm triggers.
/// Runs in a separate isolate, so must be self-contained.
@pragma('vm:entry-point')
void alarmCallback() async {
  // Show a notification from the alarm callback isolate
  final plugin = FlutterLocalNotificationsPlugin();

  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  const androidDetails = AndroidNotificationDetails(
    'yog_alarm_channel',
    'Wake-up Alarm',
    channelDescription: 'Daily morning alarm from YOG',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    playSound: true,
    enableVibration: true,
  );

  await plugin.show(
    id: 99998,
    title: '⏰ Utho Yaar! Good Morning!',
    body: 'YOG is waiting for your morning check-in. Aaj ka din shuru karo! 🌅',
    notificationDetails: const NotificationDetails(android: androidDetails),
  );
}
