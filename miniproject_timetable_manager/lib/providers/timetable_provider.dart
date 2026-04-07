import 'package:flutter/material.dart';
import '../models/timetable_model.dart';
import '../db/database_helper.dart';
import '../services/notification_service.dart';

class TimetableProvider with ChangeNotifier {
  List<Timetable> _timetables = [];
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();

  List<Timetable> get timetables => _timetables;
  bool get isLoading => _isLoading;

  /// Loads all timetable entries from the database.
  Future<void> fetchTimetables() async {
    _isLoading = true;
    notifyListeners();

    try {
      _timetables = await DatabaseHelper.instance.getAllTimetables();
    } catch (e) {
      debugPrint('Error fetching timetables: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Adds a new timetable entry, persists to DB, and schedules a notification.
  Future<void> addTimetable(Timetable timetable) async {
    try {
      final id = await DatabaseHelper.instance.insert(timetable);
      final newTimetable = timetable.copyWith(id: id);
      _timetables.add(newTimetable);
      await _notificationService.scheduleNotification(newTimetable);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding timetable: $e');
      rethrow;
    }
  }

  /// Updates an existing timetable entry, reschedules its notification.
  Future<void> updateTimetable(Timetable timetable) async {
    try {
      await DatabaseHelper.instance.update(timetable);
      final index =
          _timetables.indexWhere((element) => element.id == timetable.id);
      if (index != -1) {
        _timetables[index] = timetable;

        // Cancel old notification, schedule new one
        await _notificationService.cancelNotification(timetable.id!);
        await _notificationService.scheduleNotification(timetable);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating timetable: $e');
      rethrow;
    }
  }

  /// Deletes a timetable entry and cancels its notification.
  Future<void> deleteTimetable(int id) async {
    try {
      await DatabaseHelper.instance.delete(id);
      _timetables.removeWhere((element) => element.id == id);
      await _notificationService.cancelNotification(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting timetable: $e');
      rethrow;
    }
  }

  /// Returns timetable entries for a given day, sorted by start time (minutes).
  List<Timetable> getTimetablesByDay(String day) {
    final filtered =
        _timetables.where((element) => element.day == day).toList();
    filtered.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return filtered;
  }
}
