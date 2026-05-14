// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// App Provider (V2 master state — classes, day status)
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_entry_model.dart';
import '../models/day_status_model.dart';
import '../db/database_helper_v2.dart';
import '../services/notification_service_v2.dart';

class AppProvider with ChangeNotifier {
  List<ClassEntry> _classes = [];
  DayStatus? _todayStatus;
  bool _isLoading = false;
  Map<String, int> _weeklySummary = {};

  List<ClassEntry> get classes => _classes;
  DayStatus? get todayStatus => _todayStatus;
  bool get isLoading => _isLoading;
  Map<String, int> get weeklySummary => _weeklySummary;

  final NotificationServiceV2 _notifService = NotificationServiceV2();

  /// Load all classes and today's status.
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _classes = await DatabaseHelperV2.instance.getAllClasses();
      _weeklySummary = await DatabaseHelperV2.instance.getWeeklySummary();
      await _loadTodayStatus();
    } catch (e) {
      debugPrint('Error loading app data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadTodayStatus() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _todayStatus = await DatabaseHelperV2.instance.getDayStatus(today);
  }

  // ── Classes ──

  List<ClassEntry> getClassesByDay(String day) {
    final filtered = _classes.where((c) => c.day == day).toList();
    filtered.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return filtered;
  }

  Future<void> addClass(ClassEntry classEntry) async {
    try {
      final id = await DatabaseHelperV2.instance.insertClass(classEntry);
      final newClass = classEntry.copyWith(id: id);
      _classes.add(newClass);
      _weeklySummary = await DatabaseHelperV2.instance.getWeeklySummary();
      await _notifService.scheduleClassReminder(newClass);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding class: $e');
      rethrow;
    }
  }

  Future<void> updateClass(ClassEntry classEntry) async {
    try {
      await DatabaseHelperV2.instance.updateClass(classEntry);
      final index = _classes.indexWhere((c) => c.id == classEntry.id);
      if (index != -1) {
        _classes[index] = classEntry;
        await _notifService.cancelClassReminder(classEntry.id!);
        await _notifService.scheduleClassReminder(classEntry);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating class: $e');
      rethrow;
    }
  }

  Future<void> deleteClass(int id) async {
    try {
      await DatabaseHelperV2.instance.deleteClass(id);
      _classes.removeWhere((c) => c.id == id);
      _weeklySummary = await DatabaseHelperV2.instance.getWeeklySummary();
      await _notifService.cancelClassReminder(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting class: $e');
      rethrow;
    }
  }

  List<ClassEntry> getClassesBySubject(int subjectId) {
    return _classes.where((c) => c.subjectId == subjectId).toList();
  }

  // ── Current & Next Class ──

  ClassEntry? get currentClass {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final currentMinutes = now.hour * 60 + now.minute;

    try {
      return _classes.firstWhere((c) =>
          c.day == dayName &&
          currentMinutes >= c.startMinutes &&
          currentMinutes < c.endMinutes);
    } catch (_) {
      return null;
    }
  }

  ClassEntry? get nextClass {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final currentMinutes = now.hour * 60 + now.minute;

    final todayClasses = _classes
        .where((c) => c.day == dayName && c.startMinutes > currentMinutes)
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    if (todayClasses.isNotEmpty) return todayClasses.first;
    return null;
  }

  // ── Day Status ──

  Future<void> setTodayStatus(String status) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayStatus = DayStatus(date: today, status: status);
    await DatabaseHelperV2.instance.setDayStatus(dayStatus);
    _todayStatus = dayStatus;
    notifyListeners();
  }

  // ── Summary ──

  int get totalWeeklyClasses {
    int total = 0;
    _weeklySummary.forEach((_, count) => total += count);
    return total;
  }

  String get totalWeeklyHours {
    int totalMinutes = 0;
    for (final c in _classes) {
      final diff = c.endMinutes - c.startMinutes;
      if (diff > 0) totalMinutes += diff;
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  // ── Database Reset ──
  Future<void> deleteAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelperV2.instance.database;
      await db.delete('classes');
      await db.delete('attendance');
      await db.delete('subjects');
      await db.delete('holidays');
      await db.delete('day_status');
      
      _classes.clear();
      _weeklySummary.clear();
      _todayStatus = null;
      
      await _notifService.cancelAllV2Notifications();
    } catch (e) {
      debugPrint('Error deleting all data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
