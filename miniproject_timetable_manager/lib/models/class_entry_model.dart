// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// ClassEntry model (classes under subjects)
// ──────────────────────────────────────────────

import 'package:intl/intl.dart';

class ClassEntry {
  final int? id;
  final int subjectId;
  final String day;
  final String startTime;
  final String endTime;
  final String type;
  final String location;
  final String duration;

  // Populated via JOIN — not stored in classes table
  final String? subjectCode;
  final String? subjectCourse;
  final String? subjectFaculty;

  ClassEntry({
    this.id,
    required this.subjectId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.location,
    required this.duration,
    this.subjectCode,
    this.subjectCourse,
    this.subjectFaculty,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'location': location,
      'duration': duration,
    };
  }

  factory ClassEntry.fromMap(Map<String, dynamic> map) {
    return ClassEntry(
      id: map['id'],
      subjectId: map['subjectId'] ?? 0,
      day: map['day'] ?? 'Monday',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      type: map['type'] ?? 'Theory',
      location: map['location'] ?? '',
      duration: map['duration'] ?? '',
      subjectCode: map['subjectCode'] ?? map['code'],
      subjectCourse: map['subjectCourse'] ?? map['course'],
      subjectFaculty: map['subjectFaculty'] ?? map['faculty'],
    );
  }

  ClassEntry copyWith({
    int? id,
    int? subjectId,
    String? day,
    String? startTime,
    String? endTime,
    String? type,
    String? location,
    String? duration,
    String? subjectCode,
    String? subjectCourse,
    String? subjectFaculty,
  }) {
    return ClassEntry(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectCourse: subjectCourse ?? this.subjectCourse,
      subjectFaculty: subjectFaculty ?? this.subjectFaculty,
    );
  }

  /// Parses stored time string (e.g. "09:30 AM") into DateTime for comparison.
  DateTime get startDateTime {
    try {
      return DateFormat('hh:mm a').parse(startTime);
    } catch (_) {
      return DateTime(1970);
    }
  }

  DateTime get endDateTime {
    try {
      return DateFormat('hh:mm a').parse(endTime);
    } catch (_) {
      return DateTime(1970);
    }
  }

  /// Total minutes from midnight for reliable sorting.
  int get startMinutes {
    final dt = startDateTime;
    return dt.hour * 60 + dt.minute;
  }

  int get endMinutes {
    final dt = endDateTime;
    return dt.hour * 60 + dt.minute;
  }

  /// Check if this class is currently ongoing.
  bool get isOngoing {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    if (day != dayName) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  @override
  String toString() =>
      'ClassEntry(id: $id, subjectId: $subjectId, day: $day, startTime: $startTime)';
}
