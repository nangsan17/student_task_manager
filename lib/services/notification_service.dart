import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    tz.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await a?.requestNotificationsPermission();
    await a?.requestExactAlarmsPermission();
    await a?.createNotificationChannel(const AndroidNotificationChannel(
        'task_reminders', 'Task Reminders',
        importance: Importance.high, enableVibration: true));
    await a?.createNotificationChannel(const AndroidNotificationChannel(
        'urgent_reminders', 'Urgent Reminders',
        importance: Importance.max, enableVibration: true, playSound: true));
    _ready = true;
  }

  Future<void> scheduleTaskReminders(TaskModel task) async {
    if (kIsWeb || !_ready) return;
    await cancelTaskReminders(task.id);
    if (task.isCompleted) return;
    final dl = tz.TZDateTime.from(task.deadline, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    final d1 = dl.subtract(const Duration(hours: 24));
    final d2 = dl.subtract(const Duration(hours: 2));
    if (d1.isAfter(now))
      await _sched(task.id.hashCode, '📅 Due Tomorrow',
          '"${task.title}" due in 24h', d1, 'task_reminders');
    if (d2.isAfter(now))
      await _sched(task.id.hashCode + 1, '⏰ Due Soon',
          '"${task.title}" due in 2h!', d2, 'task_reminders');
    if (dl.isAfter(now))
      await _sched(task.id.hashCode + 2, '🔴 Deadline Now!',
          '${task.title}" deadline is NOW', dl, 'urgent_reminders');
  }

  Future<void> cancelTaskReminders(String id) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancel(id.hashCode);
    await _plugin.cancel(id.hashCode + 1);
    await _plugin.cancel(id.hashCode + 2);
  }

  Future<void> _sched(
      int id, String title, String body, tz.TZDateTime when, String ch) async {
    final d = NotificationDetails(
        android: AndroidNotificationDetails(
            ch, ch == 'urgent_reminders' ? 'Urgent' : 'Reminders',
            importance:
                ch == 'urgent_reminders' ? Importance.max : Importance.high,
            priority: Priority.high,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(body)));
    try {
      await _plugin.zonedSchedule(id, title, body, when, d,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await _plugin.zonedSchedule(id, title, body, when, d,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexact);
    }
  }
}
