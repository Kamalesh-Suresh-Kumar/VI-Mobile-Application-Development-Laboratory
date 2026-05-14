import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  group('Time Parsing Tests (Edge and Open Cases)', () {
    TimeOfDay parseTime(String t) {
      if (t.isEmpty) return const TimeOfDay(hour: 9, minute: 0);
      try { return TimeOfDay.fromDateTime(DateFormat('hh:mm a').parseLoose(t)); } catch (_) {}
      try { return TimeOfDay.fromDateTime(DateFormat.jm().parseLoose(t)); } catch (_) {}
      try { return TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(t)); } catch (_) {}
      try {
        final parts = t.toLowerCase().split(RegExp(r'[:.\s]+'));
        if (parts.length >= 2) {
          int h = int.parse(parts[0]);
          int m = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
          if (t.toLowerCase().contains('pm') && h < 12) h += 12;
          if (t.toLowerCase().contains('am') && h == 12) h = 0;
          return TimeOfDay(hour: h, minute: m);
        }
      } catch (_) {}
      return const TimeOfDay(hour: 9, minute: 0);
    }

    test('Parses standard hh:mm a format', () {
      expect(parseTime('09:30 AM'), const TimeOfDay(hour: 9, minute: 30));
      expect(parseTime('02:45 PM'), const TimeOfDay(hour: 14, minute: 45));
    });

    test('Parses lenient jm format without leading zero', () {
      expect(parseTime('9:30 AM'), const TimeOfDay(hour: 9, minute: 30));
      expect(parseTime('2:45 PM'), const TimeOfDay(hour: 14, minute: 45));
    });

    test('Parses 24-hour format (hidden edge case)', () {
      expect(parseTime('14:45'), const TimeOfDay(hour: 14, minute: 45));
      expect(parseTime('09:30'), const TimeOfDay(hour: 9, minute: 30));
    });

    test('Parses invalid or messy format using fallback regex', () {
      expect(parseTime('08.00'), const TimeOfDay(hour: 8, minute: 0));
      expect(parseTime('1.20 pm'), const TimeOfDay(hour: 13, minute: 20));
      expect(parseTime('12:00 PM'), const TimeOfDay(hour: 12, minute: 0));
      expect(parseTime('12:30 AM'), const TimeOfDay(hour: 0, minute: 30));
    });

    test('Returns default 09:00 for empty or unparseable text', () {
      expect(parseTime(''), const TimeOfDay(hour: 9, minute: 0));
      expect(parseTime('invalid string'), const TimeOfDay(hour: 9, minute: 0));
    });
  });
}
