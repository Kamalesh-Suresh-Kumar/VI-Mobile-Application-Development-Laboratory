import 'package:intl/intl.dart';

class Timetable {
  final int? id;
  final String code;
  final String course;
  final String faculty;
  final String day;
  final String time;
  final String endTime;
  final String location;
  final String duration;
  final String type;

  Timetable({
    this.id,
    required this.code,
    required this.course,
    required this.faculty,
    required this.day,
    required this.time,
    required this.endTime,
    required this.location,
    required this.duration,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'course': course,
      'faculty': faculty,
      'day': day,
      'time': time,
      'endTime': endTime,
      'location': location,
      'duration': duration,
      'type': type,
    };
  }

  factory Timetable.fromMap(Map<String, dynamic> map) {
    return Timetable(
      id: map['id'],
      code: map['code'] ?? '',
      course: map['course'] ?? '',
      faculty: map['faculty'] ?? '',
      day: map['day'] ?? 'Monday',
      time: map['time'] ?? '',
      endTime: map['endTime'] ?? '',
      location: map['location'] ?? '',
      duration: map['duration'] ?? '',
      type: map['type'] ?? 'Theory',
    );
  }

  Timetable copyWith({
    int? id,
    String? code,
    String? course,
    String? faculty,
    String? day,
    String? time,
    String? endTime,
    String? location,
    String? duration,
    String? type,
  }) {
    return Timetable(
      id: id ?? this.id,
      code: code ?? this.code,
      course: course ?? this.course,
      faculty: faculty ?? this.faculty,
      day: day ?? this.day,
      time: time ?? this.time,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      type: type ?? this.type,
    );
  }

  /// Parses the stored time string (e.g. "09:30 AM") into a DateTime for comparison.
  DateTime get startDateTime {
    try {
      return DateFormat('hh:mm a').parse(time);
    } catch (_) {
      return DateTime(1970);
    }
  }

  /// Parses the stored end time string into a DateTime for comparison.
  DateTime get endDateTime {
    try {
      return DateFormat('hh:mm a').parse(endTime);
    } catch (_) {
      return DateTime(1970);
    }
  }

  /// Returns the start time's total minutes from midnight for reliable sorting.
  int get startMinutes {
    final dt = startDateTime;
    return dt.hour * 60 + dt.minute;
  }

  @override
  String toString() {
    return 'Timetable(id: $id, code: $code, course: $course, day: $day, time: $time)';
  }
}
