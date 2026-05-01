// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Attendance record model
// ──────────────────────────────────────────────

class AttendanceRecord {
  final int? id;
  final int classId;
  final String date; // ISO 8601 date string (yyyy-MM-dd)
  final bool attended;

  AttendanceRecord({
    this.id,
    required this.classId,
    required this.date,
    required this.attended,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'date': date,
      'attended': attended ? 1 : 0,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      classId: map['classId'] ?? 0,
      date: map['date'] ?? '',
      attended: (map['attended'] ?? 0) == 1,
    );
  }

  AttendanceRecord copyWith({
    int? id,
    int? classId,
    String? date,
    bool? attended,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      attended: attended ?? this.attended,
    );
  }

  @override
  String toString() =>
      'AttendanceRecord(id: $id, classId: $classId, date: $date, attended: $attended)';
}

/// Aggregated attendance data for a subject
class SubjectAttendance {
  final int subjectId;
  final String code;
  final String course;
  final String faculty;
  final int totalClasses;
  final int attendedClasses;

  SubjectAttendance({
    required this.subjectId,
    required this.code,
    required this.course,
    required this.faculty,
    required this.totalClasses,
    required this.attendedClasses,
  });

  double get percentage =>
      totalClasses == 0 ? 0.0 : (attendedClasses / totalClasses) * 100;

  int get missedClasses => totalClasses - attendedClasses;
}
