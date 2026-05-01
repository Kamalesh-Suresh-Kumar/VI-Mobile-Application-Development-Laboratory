// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Settings Provider
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/notification_service_v2.dart';

class SettingsProvider with ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();
  final NotificationServiceV2 _notifService = NotificationServiceV2();

  bool get notificationsEnabled => _prefs.notificationsEnabled;
  int get reminderMinutes => _prefs.reminderMinutes;
  String get semesterStart => _prefs.semesterStart;
  String get semesterEnd => _prefs.semesterEnd;
  double get attendanceDangerThreshold => _prefs.attendanceDangerThreshold;
  double get attendanceWarningThreshold => _prefs.attendanceWarningThreshold;
  bool get isOnboardingDone => _prefs.isOnboardingDone;

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    if (enabled) {
      await _notifService.rescheduleAllReminders();
    } else {
      await _notifService.cancelAllV2Notifications();
    }
    notifyListeners();
  }

  Future<void> setReminderMinutes(int minutes) async {
    await _prefs.setReminderMinutes(minutes);
    await _notifService.rescheduleAllReminders();
    notifyListeners();
  }

  Future<void> setSemesterStart(String date) async {
    await _prefs.setSemesterStart(date);
    notifyListeners();
  }

  Future<void> setSemesterEnd(String date) async {
    await _prefs.setSemesterEnd(date);
    notifyListeners();
  }

  Future<void> setAttendanceDangerThreshold(double threshold) async {
    await _prefs.setAttendanceDangerThreshold(threshold);
    notifyListeners();
  }

  Future<void> setAttendanceWarningThreshold(double threshold) async {
    await _prefs.setAttendanceWarningThreshold(threshold);
    notifyListeners();
  }

  Future<void> setOnboardingDone(bool done) async {
    await _prefs.setOnboardingDone(done);
    notifyListeners();
  }
}
