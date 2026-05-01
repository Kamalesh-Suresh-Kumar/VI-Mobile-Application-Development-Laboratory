import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../onboarding/onboarding_screen.dart';

class AboutScreen extends StatelessWidget {
  final bool showGuide;
  const AboutScreen({super.key, this.showGuide = false});

  @override
  Widget build(BuildContext context) {
    if (showGuide) return OnboardingScreen(onComplete: () => Navigator.pop(context));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About', style: TextStyle(fontWeight: FontWeight.w700)), elevation: 0),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Center(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.colorScheme.primary.withAlpha(20), theme.colorScheme.tertiary.withAlpha(15)]),
          shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.primary.withAlpha(40), width: 2)),
          child: Icon(Icons.schedule_rounded, size: 64, color: theme.colorScheme.primary))),
        const SizedBox(height: 20),
        Center(child: Text(AppConstants.appName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.colorScheme.primary))),
        Center(child: Text('Version ${AppConstants.appVersion}', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withAlpha(150)))),
        const SizedBox(height: 8),
        Center(child: Text(AppConstants.appDescription, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withAlpha(180)), textAlign: TextAlign.center)),
        const SizedBox(height: 32),

        _featureCard(theme, Icons.home_rounded, 'Home Dashboard', 'Live clock, current/next class, and daily status at a glance.', const Color(0xFF6366F1)),
        _featureCard(theme, Icons.calendar_month_rounded, 'Smart Timetable', 'Subject-first architecture with weekly tabs and full CRUD.', const Color(0xFF10B981)),
        _featureCard(theme, Icons.fact_check_rounded, 'Attendance Tracking', 'Per-class attendance with color-coded indicators and customizable thresholds.', const Color(0xFFF59E0B)),
        _featureCard(theme, Icons.notifications_rounded, 'Smart Notifications', 'Configurable class reminders and morning prompts with holiday awareness.', const Color(0xFF8B5CF6)),
        _featureCard(theme, Icons.picture_as_pdf_rounded, 'PDF Export', 'Export your timetable as a professional PDF for sharing.', const Color(0xFFEF4444)),
        _featureCard(theme, Icons.event_rounded, 'Holiday Management', 'Track holidays, exams, and events with auto-notification handling.', const Color(0xFF0EA5E9)),
        const SizedBox(height: 24),
        Center(child: Text('Built with ❤️ using Flutter', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(120)))),
      ]),
    );
  }

  Widget _featureCard(ThemeData theme, IconData icon, String title, String desc, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(
      padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)), color: color.withAlpha(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(160))),
        ])),
      ]),
    ));
  }
}
