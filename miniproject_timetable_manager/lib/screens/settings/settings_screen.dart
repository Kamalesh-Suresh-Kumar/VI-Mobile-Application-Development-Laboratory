import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import 'attendance_screen.dart';
import 'holiday_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), children: [
        Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 20),

        _sectionTitle(theme, 'Academic'),
        _tile(context, Icons.fact_check_rounded, 'Attendance Overview', 'Track your subject-wise attendance', const Color(0xFF10B981),
          () { Provider.of<AttendanceProvider>(context, listen: false).fetchSummaries(); Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())); }),
        _tile(context, Icons.save_alt_rounded, 'Save Timetable (PDF)', 'Save to device storage', const Color(0xFF10B981),
          () async {
            try {
              final path = await PdfService().savePdfLocally();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('PDF saved to: $path'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                  action: SnackBarAction(label: 'OK', onPressed: () {}),
                ));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error saving PDF: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            }
          }),
        _tile(context, Icons.share_rounded, 'Share Timetable (PDF)', 'Export or share your schedule', const Color(0xFFEF4444),
          () async { await PdfService().sharePdf(); }),
        const SizedBox(height: 16),

        _sectionTitle(theme, 'Notifications'),
        Consumer<SettingsProvider>(builder: (ctx, settings, _) {
          return Column(children: [
            _switchTile(context, Icons.notifications_rounded, 'Enable Notifications', 'Class reminders & morning prompt',
              const Color(0xFF6366F1), settings.notificationsEnabled, (v) => settings.setNotificationsEnabled(v)),
            if (settings.notificationsEnabled) _reminderTile(context, settings),
          ]);
        }),
        const SizedBox(height: 16),

        _sectionTitle(theme, 'Customization'),
        Consumer<SettingsProvider>(builder: (ctx, settings, _) {
          return Column(children: [
            _switchTile(context, Icons.dark_mode_rounded, 'Dark Mode', 'Toggle dark/light theme', const Color(0xFF6366F1), settings.isDarkMode, (v) => settings.setDarkMode(v)),
            _tile(context, Icons.view_week_rounded, 'Working Days', '${settings.workingDays.length} days configured', const Color(0xFF0EA5E9),
              () => _showWorkingDaysDialog(context, settings)),
            _tile(context, Icons.tune_rounded, 'Attendance Thresholds', 'Danger: ${settings.attendanceDangerThreshold.toInt()}%  Warning: ${settings.attendanceWarningThreshold.toInt()}%', const Color(0xFF8B5CF6),
              () => _showThresholdDialog(context, settings)),
          ]);
        }),
        _tile(context, Icons.event_rounded, 'Manage Holidays', 'Add holidays, exams, and events', const Color(0xFFF59E0B),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayScreen()))),
        _tile(context, Icons.date_range_rounded, 'Semester Dates', 'Set semester start & end dates', const Color(0xFF0EA5E9),
          () => _showSemesterDatesDialog(context)),
        const SizedBox(height: 16),

        _sectionTitle(theme, 'Data Management'),
        _tile(context, Icons.delete_forever_rounded, 'Clear All Data', 'Delete all classes, attendance & settings', Colors.red,
          () => _showClearDataDialog(context)),
        const SizedBox(height: 16),

        _sectionTitle(theme, 'About'),
        _tile(context, Icons.info_outline_rounded, 'About ${AppConstants.appName}', 'Version ${AppConstants.appVersion}', const Color(0xFF6B7280),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
        _tile(context, Icons.help_outline_rounded, 'How to Use', 'View the onboarding guide again', const Color(0xFF6366F1),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen(showGuide: true)))),
      ])),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.primary, letterSpacing: 0.5)));

  Widget _tile(BuildContext ctx, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    final theme = Theme.of(ctx);
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)), color: theme.colorScheme.surface),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withAlpha(100)),
        ]),
      ),
    ));
  }

  Widget _switchTile(BuildContext ctx, IconData icon, String title, String subtitle, Color color, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(ctx);
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)), color: theme.colorScheme.surface),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 12)),
        ])),
        Switch(value: value, onChanged: onChanged),
      ]),
    ));
  }

  Widget _reminderTile(BuildContext ctx, SettingsProvider settings) {
    final theme = Theme.of(ctx);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          children: [
            // Top row: icon + label
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer_rounded, color: Color(0xFF6366F1), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reminder Time', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Notify before class', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 12)),
                ],
              )),
            ]),
            const SizedBox(height: 12),
            // Bottom row: segmented button (full width)
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: AppConstants.reminderOptions.map((m) => ButtonSegment(value: m, label: Text('${m}m'))).toList(),
                selected: {settings.reminderMinutes},
                onSelectionChanged: (v) => settings.setReminderMinutes(v.first),
                style: ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThresholdDialog(BuildContext ctx, SettingsProvider settings) {
    double danger = settings.attendanceDangerThreshold;
    double warning = settings.attendanceWarningThreshold;
    showDialog(context: ctx, builder: (c) => StatefulBuilder(builder: (c, setState2) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Attendance Thresholds'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Danger (Red) below: ${danger.toInt()}%'), Slider(value: danger, min: 50, max: 100, divisions: 50, label: '${danger.toInt()}%', onChanged: (v) => setState2(() => danger = v)),
        const SizedBox(height: 8),
        Text('Warning (Orange) below: ${warning.toInt()}%'), Slider(value: warning, min: 50, max: 100, divisions: 50, label: '${warning.toInt()}%', onChanged: (v) => setState2(() => warning = v)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(onPressed: () { settings.setAttendanceDangerThreshold(danger); settings.setAttendanceWarningThreshold(warning); Navigator.pop(c); }, child: const Text('Save'))],
    )));
  }

  void _showSemesterDatesDialog(BuildContext ctx) {
    final settings = Provider.of<SettingsProvider>(ctx, listen: false);
    showDialog(context: ctx, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Semester Dates'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(settings.semesterStart.isEmpty ? 'Set Start Date' : 'Start: ${settings.semesterStart}'), leading: const Icon(Icons.calendar_today_rounded),
          onTap: () async { final d = await showDatePicker(context: c, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) await settings.setSemesterStart(d.toIso8601String().substring(0, 10)); }),
        ListTile(title: Text(settings.semesterEnd.isEmpty ? 'Set End Date' : 'End: ${settings.semesterEnd}'), leading: const Icon(Icons.calendar_today_rounded),
          onTap: () async { final d = await showDatePicker(context: c, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) await settings.setSemesterEnd(d.toIso8601String().substring(0, 10)); }),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))],
    ));
  }

  void _showWorkingDaysDialog(BuildContext ctx, SettingsProvider settings) {
    List<String> selected = List.from(settings.workingDays);
    showDialog(context: ctx, builder: (c) => StatefulBuilder(builder: (c, setState2) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Working Days'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.allDays.map((day) => CheckboxListTile(
            title: Text(day),
            value: selected.contains(day),
            onChanged: (v) {
              setState2(() {
                if (v == true) {
                  selected.add(day);
                  // Preserve order based on allDays
                  selected.sort((a, b) => AppConstants.allDays.indexOf(a).compareTo(AppConstants.allDays.indexOf(b)));
                } else {
                  selected.remove(day);
                }
              });
            },
          )).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (selected.isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Select at least one working day')));
            return;
          }
          settings.setWorkingDays(selected);
          Navigator.pop(c);
        }, child: const Text('Save')),
      ],
    )));
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24)),
            const SizedBox(width: 12),
            const Text('Clear All Data'),
          ],
        ),
        content: const Text('Are you absolutely sure? This will permanently delete all your classes, attendance records, and custom settings. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AppProvider>(context, listen: false).deleteAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared successfully.')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
