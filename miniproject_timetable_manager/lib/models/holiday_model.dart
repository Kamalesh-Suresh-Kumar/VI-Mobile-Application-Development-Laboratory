// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Holiday model
// ──────────────────────────────────────────────

class Holiday {
  final int? id;
  final String startDate; // ISO 8601 (yyyy-MM-dd)
  final String endDate; // ISO 8601 (yyyy-MM-dd)
  final String type; // Holiday / Exam / Event
  final String description;

  Holiday({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
      'description': description,
    };
  }

  factory Holiday.fromMap(Map<String, dynamic> map) {
    return Holiday(
      id: map['id'],
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      type: map['type'] ?? 'Holiday',
      description: map['description'] ?? '',
    );
  }

  Holiday copyWith({
    int? id,
    String? startDate,
    String? endDate,
    String? type,
    String? description,
  }) {
    return Holiday(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }

  /// Check if a given date falls within this holiday range.
  bool containsDate(DateTime date) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final dateOnly = DateTime(date.year, date.month, date.day);
      return !dateOnly.isBefore(start) && !dateOnly.isAfter(end);
    } catch (_) {
      return false;
    }
  }

  @override
  String toString() =>
      'Holiday(id: $id, startDate: $startDate, endDate: $endDate, type: $type)';
}
