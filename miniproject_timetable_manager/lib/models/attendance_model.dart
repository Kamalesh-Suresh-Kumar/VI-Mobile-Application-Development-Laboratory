// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Attendance record model
// ──────────────────────────────────────────────

enum AttendanceStatus { missed, attended, od }

class AttendanceRecord {
  final int? id;
  final int classId;
  final String date; // ISO 8601 date string (yyyy-MM-dd)
  final AttendanceStatus status;

  AttendanceRecord({
    this.id,
    required this.classId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'date': date,
      'attended': status.index,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    int statusIndex = map['attended'] ?? 0;
    // Fallback if out of bounds
    if (statusIndex < 0 || statusIndex >= AttendanceStatus.values.length) statusIndex = 0;
    return AttendanceRecord(
      id: map['id'],
      classId: map['classId'] ?? 0,
      date: map['date'] ?? '',
      status: AttendanceStatus.values[statusIndex],
    );
  }

  AttendanceRecord copyWith({
    int? id,
    int? classId,
    String? date,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'AttendanceRecord(id: $id, classId: $classId, date: $date, status: $status)';
}

/// Aggregated attendance data for a subject
class SubjectAttendance {
  final int subjectId;
  final String code;
  final String course;
  final String faculty;
  final int totalClasses;
  final int attendedClasses;
  final int odClasses;

  SubjectAttendance({
    required this.subjectId,
    required this.code,
    required this.course,
    required this.faculty,
    required this.totalClasses,
    required this.attendedClasses,
    required this.odClasses,
  });

  double get percentage =>
      totalClasses == 0 ? 0.0 : ((attendedClasses + odClasses) / totalClasses) * 100;

  int get missedClasses => totalClasses - attendedClasses - odClasses;
}
