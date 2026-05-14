// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// SharedPreferences service
// ──────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ── Onboarding ──
  bool get isOnboardingDone =>
      prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool done) =>
      prefs.setBool(AppConstants.prefOnboardingDone, done);

  // ── Notifications ──
  bool get notificationsEnabled =>
      prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool enabled) =>
      prefs.setBool(AppConstants.prefNotificationsEnabled, enabled);

  int get reminderMinutes =>
      prefs.getInt(AppConstants.prefReminderMinutes) ?? 10;
  Future<void> setReminderMinutes(int minutes) =>
      prefs.setInt(AppConstants.prefReminderMinutes, minutes);

  // ── Semester dates ──
  String get semesterStart =>
      prefs.getString(AppConstants.prefSemesterStart) ?? '';
  Future<void> setSemesterStart(String date) =>
      prefs.setString(AppConstants.prefSemesterStart, date);

  String get semesterEnd => prefs.getString(AppConstants.prefSemesterEnd) ?? '';
  Future<void> setSemesterEnd(String date) =>
      prefs.setString(AppConstants.prefSemesterEnd, date);

  // ── Attendance thresholds ──
  double get attendanceDangerThreshold =>
      prefs.getDouble(AppConstants.prefAttendanceDanger) ??
      AppConstants.attendanceDangerThreshold;
  Future<void> setAttendanceDangerThreshold(double threshold) =>
      prefs.setDouble(AppConstants.prefAttendanceDanger, threshold);

  double get attendanceWarningThreshold =>
      prefs.getDouble(AppConstants.prefAttendanceWarning) ??
      AppConstants.attendanceWarningThreshold;
  Future<void> setAttendanceWarningThreshold(double threshold) =>
      prefs.setDouble(AppConstants.prefAttendanceWarning, threshold);

  // ── Theme ──
  bool get isDarkMode => prefs.getBool(AppConstants.prefDarkMode) ?? false;
  Future<void> setDarkMode(bool value) => prefs.setBool(AppConstants.prefDarkMode, value);

  // ── Working Days ──
  List<String> get workingDays => prefs.getStringList(AppConstants.prefWorkingDays) ?? AppConstants.weekDays;
  Future<void> setWorkingDays(List<String> days) => prefs.setStringList(AppConstants.prefWorkingDays, days);

  // ── Timetable lifecycle ──
  String get timetableCreatedAt => prefs.getString(AppConstants.prefTimetableCreated) ?? '';
  Future<void> setTimetableCreatedAt(String date) => prefs.setString(AppConstants.prefTimetableCreated, date);
}
