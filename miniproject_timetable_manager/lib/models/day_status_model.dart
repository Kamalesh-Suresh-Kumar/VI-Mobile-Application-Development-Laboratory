// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Day status model (going/holiday/leave/od)
// ──────────────────────────────────────────────

class DayStatus {
  final int? id;
  final String date; // ISO 8601 (yyyy-MM-dd)
  final String status; // going / holiday / leave / od

  DayStatus({
    this.id,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'status': status,
    };
  }

  factory DayStatus.fromMap(Map<String, dynamic> map) {
    return DayStatus(
      id: map['id'],
      date: map['date'] ?? '',
      status: map['status'] ?? 'going',
    );
  }

  DayStatus copyWith({
    int? id,
    String? date,
    String? status,
  }) {
    return DayStatus(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  /// Human-readable label
  String get label {
    switch (status) {
      case 'going':
        return 'Going to College';
      case 'holiday':
        return 'Holiday';
      case 'leave':
        return 'Leave';
      case 'od':
        return 'On Duty (OD)';
      default:
        return status;
    }
  }

  /// Emoji representation
  String get emoji {
    switch (status) {
      case 'going':
        return '🎓';
      case 'holiday':
        return '🏖️';
      case 'leave':
        return '🏠';
      case 'od':
        return '💼';
      default:
        return '📅';
    }
  }

  @override
  String toString() => 'DayStatus(date: $date, status: $status)';
}
