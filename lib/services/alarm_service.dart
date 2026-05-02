import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class AlarmService {
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleAlarm(int id, DateTime dateTime) async {
    // Schedule alarm using android_alarm_manager_plus
    // This requires a static callback function
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

// Global scope function for alarm callback
@pragma('vm:entry-point')
void alarmCallback() {
  print("Alarm fired!");
  // In a real app, this would trigger a notification or launch the app activity
  // using flutter_local_notifications or a custom Android intent.
}
