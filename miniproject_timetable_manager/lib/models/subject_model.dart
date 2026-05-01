// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Subject model (subject-first architecture)
// ──────────────────────────────────────────────

class Subject {
  final int? id;
  final String code;
  final String course;
  final String faculty;

  Subject({
    this.id,
    required this.code,
    required this.course,
    required this.faculty,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'course': course,
      'faculty': faculty,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      code: map['code'] ?? '',
      course: map['course'] ?? '',
      faculty: map['faculty'] ?? '',
    );
  }

  Subject copyWith({
    int? id,
    String? code,
    String? course,
    String? faculty,
  }) {
    return Subject(
      id: id ?? this.id,
      code: code ?? this.code,
      course: course ?? this.course,
      faculty: faculty ?? this.faculty,
    );
  }

  @override
  String toString() =>
      'Subject(id: $id, code: $code, course: $course, faculty: $faculty)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
