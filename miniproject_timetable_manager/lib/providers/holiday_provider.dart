// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Holiday Provider
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/holiday_model.dart';
import '../db/database_helper_v2.dart';
import '../services/notification_service_v2.dart';

class HolidayProvider with ChangeNotifier {
  List<Holiday> _holidays = [];
  bool _isLoading = false;

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _isLoading;

  final NotificationServiceV2 _notifService = NotificationServiceV2();

  Future<void> fetchHolidays() async {
    _isLoading = true;
    notifyListeners();

    try {
      _holidays = await DatabaseHelperV2.instance.getAllHolidays();
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHoliday(Holiday holiday) async {
    try {
      final id = await DatabaseHelperV2.instance.insertHoliday(holiday);
      _holidays.add(holiday.copyWith(id: id));
      _holidays.sort((a, b) => a.startDate.compareTo(b.startDate));
      // Reschedule notifications to skip holidays
      await _notifService.rescheduleAllReminders();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding holiday: $e');
      rethrow;
    }
  }

  Future<void> updateHoliday(Holiday holiday) async {
    try {
      await DatabaseHelperV2.instance.updateHoliday(holiday);
      final index = _holidays.indexWhere((h) => h.id == holiday.id);
      if (index != -1) {
        _holidays[index] = holiday;
        _holidays.sort((a, b) => a.startDate.compareTo(b.startDate));
        await _notifService.rescheduleAllReminders();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating holiday: $e');
      rethrow;
    }
  }

  Future<void> deleteHoliday(int id) async {
    try {
      await DatabaseHelperV2.instance.deleteHoliday(id);
      _holidays.removeWhere((h) => h.id == id);
      await _notifService.rescheduleAllReminders();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting holiday: $e');
      rethrow;
    }
  }

  /// Check if today is a custom holiday.
  bool isTodayHoliday() {
    final now = DateTime.now();
    return _holidays.any((h) => h.containsDate(now));
  }

  /// Check if a specific date is a holiday.
  bool isDateHoliday(DateTime date) {
    return _holidays.any((h) => h.containsDate(date));
  }
}
