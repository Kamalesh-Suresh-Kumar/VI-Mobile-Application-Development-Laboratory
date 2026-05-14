// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// App-wide constants and configuration
// ──────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'SchedIQ';
  static const String appVersion = '2.0.0';
  static const String appDescription =
      'Smart Timetable Manager — Track classes, attendance & more.';

  // Days
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const List<String> allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Class types
  static const List<String> classTypes = ['Theory', 'Lab', 'Aptitude'];

  // Holiday types
  static const List<String> holidayTypes = ['Holiday', 'Exam', 'Event'];

  // Day statuses
  static const List<String> dayStatuses = ['going', 'holiday', 'leave', 'od'];

  // Notification reminder options (in minutes)
  static const List<int> reminderOptions = [5, 10, 15];

  // Morning prompt time
  static const int morningPromptHour = 7;
  static const int morningPromptMinute = 15;

  // Default attendance thresholds
  static const double attendanceDangerThreshold = 70.0;
  static const double attendanceWarningThreshold = 75.0;

  // SharedPreferences keys
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefReminderMinutes = 'reminder_minutes';
  static const String prefSemesterStart = 'semester_start';
  static const String prefSemesterEnd = 'semester_end';
  static const String prefAttendanceDanger = 'attendance_danger';
  static const String prefAttendanceWarning = 'attendance_warning';
  static const String prefDarkMode = 'dark_mode';
  static const String prefWorkingDays = 'working_days';
  static const String prefTimetableCreated = 'timetable_created';
}
