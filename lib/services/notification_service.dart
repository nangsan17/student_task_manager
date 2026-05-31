import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
        'task_reminders', 'Task Reminders', importance: Importance.high));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
        'urgent_reminders', 'Urgent Reminders', importance: Importance.max));
  }

  Future<void> scheduleTaskReminders(TaskModel task) async {
    await cancelTaskReminders(task.id);
    if (task.isCompleted) return;
    final dl  = tz.TZDateTime.from(task.deadline, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    final d1  = dl.subtract(const Duration(hours: 24));
    final d2  = dl.subtract(const Duration(hours: 2));
    if (d1.isAfter(now)) await _schedule(task.id.hashCode,     '📅 Due Tomorrow', '"${task.title}" due in 24h', d1, 'task_reminders');
    if (d2.isAfter(now)) await _schedule(task.id.hashCode + 1, '⏰ Due Soon',     '"${task.title}" due in 2h!', d2, 'task_reminders');
    if (dl.isAfter(now)) await _schedule(task.id.hashCode + 2, '🔴 Deadline Now!', '"${task.title}" due NOW',   dl, 'urgent_reminders');
  }

  Future<void> cancelTaskReminders(String taskId) async {
    await _plugin.cancel(taskId.hashCode);
    await _plugin.cancel(taskId.hashCode + 1);
    await _plugin.cancel(taskId.hashCode + 2);
  }

  Future<void> _schedule(int id, String title, String body, tz.TZDateTime when, String ch) async {
    await _plugin.zonedSchedule(id, title, body, when,
      NotificationDetails(android: AndroidNotificationDetails(ch, ch,
          importance: ch == 'urgent_reminders' ? Importance.max : Importance.high,
          priority: Priority.high)),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
