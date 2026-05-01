// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Enhanced Notification Service
// Supports configurable reminder times, morning prompts, holiday awareness
// ──────────────────────────────────────────────

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:intl/intl.dart';
import '../models/class_entry_model.dart';
import '../db/database_helper_v2.dart';
import 'preferences_service.dart';

class NotificationServiceV2 {
  static final NotificationServiceV2 _instance =
      NotificationServiceV2._internal();
  factory NotificationServiceV2() => _instance;
  NotificationServiceV2._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification ID ranges to avoid collision with V1
  static const int _classBaseId = 10000;
  static const int _morningPromptId = 99999;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    tzdata.initializeTimeZones();

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap — can be extended for navigation
  }

  // ──────────────────────────────────────
  // CLASS REMINDERS
  // ──────────────────────────────────────

  /// Schedule a notification [reminderMinutes] before a class.
  Future<void> scheduleClassReminder(
    ClassEntry classEntry, {
    int? reminderMinutes,
  }) async {
    if (classEntry.id == null) return;

    final prefs = PreferencesService();
    if (!prefs.notificationsEnabled) return;

    final minutes = reminderMinutes ?? prefs.reminderMinutes;

    try {
      final startTime = DateFormat('hh:mm a').parse(classEntry.startTime);
      final now = DateTime.now();
      final int targetWeekday = _getDayIndex(classEntry.day);

      // Build DateTime for the class this week
      DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      // Advance to the correct weekday
      while (scheduledDate.weekday != targetWeekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Check if this day is a holiday
      final isHoliday =
          await DatabaseHelperV2.instance.isHoliday(scheduledDate);
      if (isHoliday) return;

      DateTime notificationTime =
          scheduledDate.subtract(Duration(minutes: minutes));

      if (notificationTime.isBefore(now)) {
        notificationTime = notificationTime.add(const Duration(days: 7));
      }

      final tzTime = tz.TZDateTime.from(notificationTime, tz.local);
      final notifId = _classBaseId + classEntry.id!;
      final courseName = classEntry.subjectCourse ?? 'Class';
      final faculty = classEntry.subjectFaculty ?? '';

      await _plugin.zonedSchedule(
        id: notifId,
        title: '📚 Upcoming: $courseName',
        body:
            '${classEntry.startTime} — ${classEntry.location}${faculty.isNotEmpty ? ' with $faculty' : ''}',
        scheduledDate: tzTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'schediq_class_channel',
            'Class Reminders',
            channelDescription: 'Notifications before your classes',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      _log('Failed to schedule class reminder: $e');
    }
  }

  /// Cancel a class reminder.
  Future<void> cancelClassReminder(int classId) async {
    await _plugin.cancel(id: _classBaseId + classId);
  }

  // ──────────────────────────────────────
  // MORNING PROMPT
  // ──────────────────────────────────────

  /// Schedule the daily 7:15 AM "Are you going to college?" prompt.
  Future<void> scheduleMorningPrompt() async {
    final prefs = PreferencesService();
    if (!prefs.notificationsEnabled) return;

    try {
      final now = DateTime.now();
      DateTime promptTime = DateTime(
        now.year,
        now.month,
        now.day,
        7,
        15,
      );

      // If we've already passed 7:15 today, schedule for tomorrow
      if (promptTime.isBefore(now)) {
        promptTime = promptTime.add(const Duration(days: 1));
      }

      // Skip weekends
      while (promptTime.weekday == DateTime.saturday ||
          promptTime.weekday == DateTime.sunday) {
        promptTime = promptTime.add(const Duration(days: 1));
      }

      final tzTime = tz.TZDateTime.from(promptTime, tz.local);

      await _plugin.zonedSchedule(
        id: _morningPromptId,
        title: '🌅 Good Morning!',
        body: 'Are you going to college today? Tap to set your status.',
        scheduledDate: tzTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'schediq_morning_channel',
            'Morning Prompt',
            channelDescription: 'Daily college attendance prompt',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      _log('Failed to schedule morning prompt: $e');
    }
  }

  /// Cancel the morning prompt.
  Future<void> cancelMorningPrompt() async {
    await _plugin.cancel(id: _morningPromptId);
  }

  // ──────────────────────────────────────
  // BULK OPERATIONS
  // ──────────────────────────────────────

  /// Reschedule all class reminders (call on app restart).
  Future<void> rescheduleAllReminders() async {
    final prefs = PreferencesService();
    if (!prefs.notificationsEnabled) return;

    try {
      // Cancel all V2 notifications first
      await cancelAllV2Notifications();

      // Reschedule class reminders
      final classes = await DatabaseHelperV2.instance.getAllClasses();
      for (final classEntry in classes) {
        await scheduleClassReminder(classEntry);
      }

      // Reschedule morning prompt
      await scheduleMorningPrompt();
    } catch (e) {
      _log('Failed to reschedule reminders: $e');
    }
  }

  /// Cancel all V2 notifications (preserves V1 notifications).
  Future<void> cancelAllV2Notifications() async {
    // Cancel morning prompt
    await _plugin.cancel(id: _morningPromptId);

    // Cancel class reminders by fetching all classes
    try {
      final classes = await DatabaseHelperV2.instance.getAllClasses();
      for (final c in classes) {
        if (c.id != null) {
          await _plugin.cancel(id: _classBaseId + c.id!);
        }
      }
    } catch (e) {
      _log('Failed to cancel V2 notifications: $e');
    }
  }

  // ──────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────

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

  void _log(String message) {
    // ignore: avoid_print
    print('[NotificationServiceV2] $message');
  }
}
