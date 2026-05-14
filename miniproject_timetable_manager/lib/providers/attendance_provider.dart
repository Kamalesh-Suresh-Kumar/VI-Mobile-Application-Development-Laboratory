// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Attendance Provider
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../db/database_helper_v2.dart';

class AttendanceProvider with ChangeNotifier {
  List<SubjectAttendance> _summaries = [];
  bool _isLoading = false;

  List<SubjectAttendance> get summaries => _summaries;
  bool get isLoading => _isLoading;

  Future<void> fetchSummaries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _summaries =
          await DatabaseHelperV2.instance.getSubjectAttendanceSummary();
    } catch (e) {
      debugPrint('Error fetching attendance summaries: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Mark attendance for a class on a given date.
  Future<void> markAttendance({
    required int classId,
    required String date,
    required AttendanceStatus status,
  }) async {
    try {
      // Check if record exists
      final existing = await DatabaseHelperV2.instance
          .getAttendanceForClassOnDate(classId, date);

      if (existing != null) {
        await DatabaseHelperV2.instance
            .updateAttendance(existing.copyWith(status: status));
      } else {
        await DatabaseHelperV2.instance.insertAttendance(
          AttendanceRecord(
            classId: classId,
            date: date,
            status: status,
          ),
        );
      }

      await fetchSummaries();
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      rethrow;
    }
  }

  /// Get attendance records for a specific class.
  Future<List<AttendanceRecord>> getClassAttendance(int classId) async {
    try {
      return await DatabaseHelperV2.instance.getAttendanceByClass(classId);
    } catch (e) {
      debugPrint('Error getting class attendance: $e');
      return [];
    }
  }

  /// Delete an attendance record.
  Future<void> deleteAttendance(int id) async {
    try {
      await DatabaseHelperV2.instance.deleteAttendance(id);
      await fetchSummaries();
    } catch (e) {
      debugPrint('Error deleting attendance: $e');
      rethrow;
    }
  }
}
