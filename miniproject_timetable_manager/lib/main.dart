// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Main entry point (preserves V1 compatibility)
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// V1 imports (preserved)
import 'providers/timetable_provider.dart';
import 'services/notification_service.dart';

// V2 imports
import 'providers/app_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/holiday_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service_v2.dart';
import 'services/preferences_service.dart';
import 'db/database_helper_v2.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize V1 notification service (backward compat)
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize V2 services
  final prefsService = PreferencesService();
  await prefsService.init();

  final notifServiceV2 = NotificationServiceV2();
  await notifServiceV2.init();

  // Initialize V2 database (triggers migration if needed)
  await DatabaseHelperV2.instance.database;

  // Reschedule all V2 notifications on app start
  await notifServiceV2.rescheduleAllReminders();

  runApp(
    MultiProvider(
      providers: [
        // V1 provider (preserved)
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        // V2 providers
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const SchedIQApp(),
    ),
  );
}

class SchedIQApp extends StatefulWidget {
  const SchedIQApp({super.key});

  @override
  State<SchedIQApp> createState() => _SchedIQAppState();
}

class _SchedIQAppState extends State<SchedIQApp> {
  bool _showOnboarding = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  void _checkOnboarding() {
    final prefs = PreferencesService();
    setState(() {
      _showOnboarding = !prefs.isOnboardingDone;
      _initialized = true;
    });
  }

  void _onOnboardingComplete() {
    setState(() => _showOnboarding = false);
    // Load initial data
    _loadData();
  }

  void _loadData() {
    final ctx = context;
    Provider.of<AppProvider>(ctx, listen: false).loadAll();
    Provider.of<SubjectProvider>(ctx, listen: false).fetchSubjects();
    Provider.of<HolidayProvider>(ctx, listen: false).fetchHolidays();
    Provider.of<AttendanceProvider>(ctx, listen: false).fetchSummaries();
    // Also load V1 data for backward compatibility
    Provider.of<TimetableProvider>(ctx, listen: false).fetchTimetables();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.buildLightTheme(),
          darkTheme: AppTheme.buildDarkTheme(),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: !_initialized
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _showOnboarding
                  ? OnboardingScreen(onComplete: _onOnboardingComplete)
                  : Builder(
                      builder: (context) {
                        Future.microtask(() {
                          _loadData();
                          _check45DayReset(context);
                        });
                        return const AppShell();
                      },
                    ),
        );
      },
    );
  }

  void _check45DayReset(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final createdStr = settings.timetableCreatedAt;
    
    if (createdStr.isEmpty) {
      await settings.setTimetableCreatedAt(DateTime.now().toIso8601String());
      return;
    }

    final createdAt = DateTime.tryParse(createdStr);
    if (createdAt == null) return;

    final daysPassed = DateTime.now().difference(createdAt).inDays;
    if (daysPassed >= 45) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: const Text('New Semester?'),
          content: const Text('It has been 45 days since you created this timetable. Would you like to clear all classes and attendance to start fresh for a new semester?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                // Ask when to remind again
                showDialog(
                  context: context,
                  builder: (c2) => AlertDialog(
                    title: const Text('Remind Me Later'),
                    content: const Text('When should we remind you again?'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          // Remind in 7 days
                          await settings.setTimetableCreatedAt(DateTime.now().add(const Duration(days: 7 - 45)).toIso8601String());
                          if (context.mounted) Navigator.pop(c2);
                        },
                        child: const Text('In 7 Days'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Ignore entirely (reset to now so it waits 45 days again)
                          await settings.setTimetableCreatedAt(DateTime.now().toIso8601String());
                          if (context.mounted) Navigator.pop(c2);
                        },
                        child: const Text('Do Not Remind'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Not Now'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                await appProvider.deleteAllData();
                await settings.setTimetableCreatedAt(DateTime.now().toIso8601String());
                if (context.mounted) Navigator.pop(c);
              },
              child: const Text('Yes, Clear All'),
            ),
          ],
        ),
      );
    }
  }
}
