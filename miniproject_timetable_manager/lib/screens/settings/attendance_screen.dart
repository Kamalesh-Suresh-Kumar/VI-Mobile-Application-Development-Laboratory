import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/attendance_indicator.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Overview', style: TextStyle(fontWeight: FontWeight.w700)), elevation: 0),
      body: Consumer2<AttendanceProvider, SettingsProvider>(builder: (ctx, attendance, settings, _) {
        if (attendance.isLoading) return const Center(child: CircularProgressIndicator());
        if (attendance.summaries.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withAlpha(50), shape: BoxShape.circle),
            child: Icon(Icons.fact_check_outlined, size: 56, color: theme.colorScheme.primary.withAlpha(120))),
          const SizedBox(height: 24),
          Text('No attendance data', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(180))),
          const SizedBox(height: 8),
          Text('Mark attendance from the timetable tab', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120)), textAlign: TextAlign.center),
        ]));

        return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), itemCount: attendance.summaries.length, itemBuilder: (ctx, i) {
          return Padding(padding: const EdgeInsets.only(bottom: 12),
            child: AttendanceIndicator(attendance: attendance.summaries[i], dangerThreshold: settings.attendanceDangerThreshold, warningThreshold: settings.attendanceWarningThreshold));
        });
      }),
    );
  }
}
