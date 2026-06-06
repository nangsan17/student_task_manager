import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:async';
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final Map<String, Timer> _taskTimers = {};

  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_deadline_channel',
      'Task Deadlines',
      description: 'Notifications for task deadlines',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    print('✓ Notification Service Initialized');
  }

  // ============================================================================
  // TEST NOTIFICATION (Manual)
  // ============================================================================
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'task_deadline_channel',
      'Task Deadlines',
      channelDescription: 'Notifications for task deadlines',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentBadge: true,
        presentAlert: true,
      ),
    );

    await _localNotifications.show(
      9999,
      'Test Notification',
      '✓ SPTM notifications are active',
      notificationDetails,
    );

    print('✓ Test notification sent');
  }

  // ============================================================================
  // SCHEDULE TASK REMINDERS (Using Timers)
  // ============================================================================
  Future<void> scheduleTaskReminders(TaskModel task) async {
    try {
      final now = DateTime.now();
      final deadline = task.deadline;

      print(
          '📅 Scheduling reminders for task: ${task.title} (deadline: $deadline)');

      // Cancel existing timers for this task
      _taskTimers[task.id]?.cancel();

      // Only schedule if deadline is in the future
      if (deadline.isBefore(now)) {
        print('⚠️ Deadline is in the past, skipping');
        return;
      }

      // ═══════════════════════════════════════════════════════════════════
      // REMINDER 1: 24 hours before deadline
      // ═══════════════════════════════════════════════════════════════════
      final reminder24h = deadline.subtract(const Duration(hours: 24));
      if (reminder24h.isAfter(now)) {
        final delay = reminder24h.difference(now);
        Timer(delay, () async {
          await _showNotification(
            id: task.id.hashCode,
            title: '📢 Task Due Soon',
            body: '${task.title} - Due in 24 hours',
          );
        });
        print('✓ Timer set for 24h reminder in ${delay.inMinutes} minutes');
      }

      // ═══════════════════════════════════════════════════════════════════
      // REMINDER 2: 2 hours before deadline
      // ═══════════════════════════════════════════════════════════════════
      final reminder2h = deadline.subtract(const Duration(hours: 2));
      if (reminder2h.isAfter(now)) {
        final delay = reminder2h.difference(now);
        Timer(delay, () async {
          await _showNotification(
            id: task.id.hashCode + 1,
            title: '⏰ Task Due Soon!',
            body: '${task.title} - Due in 2 hours',
          );
        });
        print('✓ Timer set for 2h reminder in ${delay.inMinutes} minutes');
      }

      // ═══════════════════════════════════════════════════════════════════
      // REMINDER 3: AT deadline
      // ═══════════════════════════════════════════════════════════════════
      if (deadline.isAfter(now)) {
        final delay = deadline.difference(now);
        _taskTimers[task.id] = Timer(delay, () async {
          await _showNotification(
            id: task.id.hashCode + 2,
            title: '🔔 Task Deadline NOW',
            body: '${task.title} - Deadline is now!',
          );
        });
        print(
            '✓ Timer set for deadline reminder in ${delay.inMinutes} minutes (${delay.inSeconds} seconds)');
      }

      print('✅ All reminders scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling reminders: $e');
    }
  }

  // ============================================================================
  // INTERNAL: Show notification
  // ============================================================================
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'task_deadline_channel',
        'Task Deadlines',
        channelDescription: 'Notifications for task deadlines',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
        ),
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
      );

      print('🔔 Notification shown: $title');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  // ============================================================================
  // RESCHEDULE ALL — call on app startup to set up timers for active tasks
  // ============================================================================
  Future<void> rescheduleAllReminders(List<TaskModel> tasks) async {
    print(
        '🔄 Setting up timers for ${tasks.length} active task(s)...');
    for (final task in tasks) {
      try {
        await scheduleTaskReminders(task);
      } catch (e) {
        print('❌ Failed to reschedule "${task.title}": $e');
      }
    }
    print('✅ All timers set up');
  }

  // ============================================================================
  // CLEANUP (Cancel notifications for a task)
  // ============================================================================
  Future<void> cancelTaskReminders(String taskId) async {
    try {
      // Cancel timers
      _taskTimers[taskId]?.cancel();
      _taskTimers.remove(taskId);

      // Cancel displayed notifications
      await _localNotifications.cancel(taskId.hashCode);
      await _localNotifications.cancel(taskId.hashCode + 1);
      await _localNotifications.cancel(taskId.hashCode + 2);

      print('✓ Notifications cancelled for task: $taskId');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }
}
