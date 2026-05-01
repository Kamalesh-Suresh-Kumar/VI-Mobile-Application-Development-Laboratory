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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.buildLightTheme(),
      darkTheme: AppTheme.buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: !_initialized
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _showOnboarding
              ? OnboardingScreen(onComplete: _onOnboardingComplete)
              : Builder(
                  builder: (context) {
                    // Load data when the app shell is first built
                    Future.microtask(() => _loadData());
                    return const AppShell();
                  },
                ),
    );
  }
}
