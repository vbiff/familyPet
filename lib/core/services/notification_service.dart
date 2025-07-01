import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  taskDeadline,
  taskCompleted,
  familyActivity,
  petUpdate,
  weeklyReport,
  reminderDaily,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    if (!kIsWeb && Platform.isAndroid) {
      tz.setLocalLocation(tz.getLocation('America/New_York'));
    }

    const androidInitializationSettings =
        AndroidInitializationSettings('app_icon');

    const darwinInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
      macOS: darwinInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
  }

  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // Handle iOS foreground notification
    debugPrint('Received local notification: $title');
  }

  static void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');
      await _handleNotificationTap(payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Background notification payload: $payload');
      await _handleNotificationTap(payload);
    }
  }

  static Future<void> _handleNotificationTap(String payload) async {
    // Parse payload and navigate to appropriate screen
    // Implementation depends on app routing structure
    debugPrint('Handling notification tap: $payload');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.requestNotificationsPermission() ??
          false;
    }
    return true;
  }

  Future<void> scheduleTaskDeadlineNotification(Task task) async {
    if (!_isInitialized) await initialize();

    final scheduledDate = task.dueDate.subtract(const Duration(hours: 1));
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      task.id.hashCode,
      'Task Reminder',
      '⏰ "${task.title}" is due in 1 hour!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_deadlines',
          'Task Deadlines',
          channelDescription: 'Notifications for upcoming task deadlines',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'task_icon',
          color: Colors.indigo,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'TASK_CATEGORY',
          threadIdentifier: 'task_deadlines',
        ),
      ),
      payload: 'task_deadline:${task.id}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> notifyTaskCompleted(Task task, String childName) async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.show(
      task.id.hashCode + 1000,
      'Task Completed! 🎉',
      '$childName just completed "${task.title}"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_completed',
          'Task Completed',
          channelDescription: 'Notifications when children complete tasks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'success_icon',
          color: Colors.green,
          largeIcon: DrawableResourceAndroidBitmap('celebration_large'),
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'TASK_COMPLETED_CATEGORY',
          threadIdentifier: 'task_completed',
        ),
      ),
      payload: 'task_completed:${task.id}',
    );
  }

  Future<void> notifyFamilyActivity(String activity, String memberName) async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Family Activity',
      '$memberName $activity',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'family_activity',
          'Family Activity',
          channelDescription: 'Updates about family member activities',
          importance: Importance.low,
          priority: Priority.low,
          icon: 'family_icon',
          color: Colors.purple,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'FAMILY_ACTIVITY_CATEGORY',
          threadIdentifier: 'family_activity',
        ),
      ),
      payload: 'family_activity:$memberName',
    );
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      999, // Fixed ID for daily reminder
      'Daily Check-in 📋',
      'Don\'t forget to check your tasks for today!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily task reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'reminder_icon',
          color: Colors.amber,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'DAILY_REMINDER_CATEGORY',
          threadIdentifier: 'daily_reminders',
        ),
      ),
      payload: 'daily_reminder',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleWeeklyReport() async {
    if (!_isInitialized) await initialize();

    // Schedule for every Sunday at 6 PM
    final nextSunday = _nextInstanceOfWeekday(DateTime.sunday, 18, 0);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      998, // Fixed ID for weekly report
      'Weekly Report Available! 📊',
      'Check out your family\'s progress this week',
      nextSunday,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reports',
          'Weekly Reports',
          channelDescription: 'Weekly family progress reports',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'report_icon',
          color: Colors.blue,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'WEEKLY_REPORT_CATEGORY',
          threadIdentifier: 'weekly_reports',
        ),
      ),
      payload: 'weekly_report',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode + 1000);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'task_deadlines',
        'Task Deadlines',
        description: 'Notifications for upcoming task deadlines',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      AndroidNotificationChannel(
        'task_completed',
        'Task Completed',
        description: 'Notifications when children complete tasks',
        importance: Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound('success_sound'),
      ),
      AndroidNotificationChannel(
        'family_activity',
        'Family Activity',
        description: 'Updates about family member activities',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'daily_reminders',
        'Daily Reminders',
        description: 'Daily task reminders',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'weekly_reports',
        'Weekly Reports',
        description: 'Weekly family progress reports',
        importance: Importance.defaultImportance,
      ),
    ];

    final plugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      for (final channel in channels) {
        await plugin.createNotificationChannel(channel);
      }
    }
  }
}
