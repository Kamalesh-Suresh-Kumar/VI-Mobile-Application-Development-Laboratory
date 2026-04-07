import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:intl/intl.dart';
import '../models/timetable_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    tzdata.initializeTimeZones();

    // v21 API: all named parameters
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap if needed
  }

  /// Schedules a notification 10 minutes before the class start time.
  /// Uses [matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime]
  /// so the notification repeats every week on the same day/time.
  Future<void> scheduleNotification(Timetable timetable) async {
    if (timetable.id == null) return;

    try {
      final startTime = DateFormat('hh:mm a').parse(timetable.time);
      final now = DateTime.now();

      final int targetWeekday = _getDayIndex(timetable.day);

      // Build a DateTime for the class this week
      DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      // Move forward to reach the correct weekday
      while (scheduledDate.weekday != targetWeekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // The notification fires 10 minutes before the class
      DateTime notificationTime =
          scheduledDate.subtract(const Duration(minutes: 10));

      // If we've already passed this week's notification time, push to next week
      if (notificationTime.isBefore(now)) {
        notificationTime = notificationTime.add(const Duration(days: 7));
      }

      final tzNotificationTime =
          tz.TZDateTime.from(notificationTime, tz.local);

      // v21 API: all named parameters, no uiLocalNotificationDateInterpretation
      await _plugin.zonedSchedule(
        id: timetable.id!,
        title: 'Upcoming Class',
        body:
            '${timetable.course} with ${timetable.faculty} at ${timetable.location}',
        scheduledDate: tzNotificationTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'timetable_channel',
            'Timetable Notifications',
            channelDescription: 'Notifications for upcoming classes',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      // Silently handle parse errors so the app doesn't crash
      _debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Cancels a scheduled notification by its ID.
  Future<void> cancelNotification(int id) async {
    // v21 API: named parameter
    await _plugin.cancel(id: id);
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  int _getDayIndex(String day) {
    const dayMap = {
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
      'Sunday': DateTime.sunday,
    };
    return dayMap[day] ?? DateTime.monday;
  }

  void _debugPrint(String message) {
    // ignore: avoid_print
    print('[NotificationService] $message');
  }
}
