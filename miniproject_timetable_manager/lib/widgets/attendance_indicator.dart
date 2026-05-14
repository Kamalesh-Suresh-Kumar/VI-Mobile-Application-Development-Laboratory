// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Attendance Color Indicator Widget
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../utils/theme.dart';

class AttendanceIndicator extends StatelessWidget {
  final SubjectAttendance attendance;
  final double dangerThreshold;
  final double warningThreshold;
  final VoidCallback? onTap;

  const AttendanceIndicator({
    super.key,
    required this.attendance,
    this.dangerThreshold = 70.0,
    this.warningThreshold = 75.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.getAttendanceColor(
      attendance.percentage,
      dangerThreshold: dangerThreshold,
      warningThreshold: warningThreshold,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha(60),
            width: 1.5,
          ),
          color: color.withAlpha(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attendance.course,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        attendance.code,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Percentage circle
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: attendance.totalClasses == 0
                            ? 0
                            : attendance.percentage / 100,
                        backgroundColor: color.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 5,
                      ),
                      Text(
                        attendance.totalClasses == 0
                            ? 'N/A'
                            : '${attendance.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: attendance.totalClasses == 0 ? 10 : 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  context,
                  'Total',
                  attendance.totalClasses.toString(),
                  theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  'Attended',
                  attendance.attendedClasses.toString(),
                  AppTheme.attendanceGood,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  'Missed',
                  attendance.missedClasses.toString(),
                  AppTheme.attendanceDanger,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  'OD',
                  attendance.odClasses.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withAlpha(180),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
