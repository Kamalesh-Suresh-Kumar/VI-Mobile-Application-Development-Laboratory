// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Subject Provider
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../db/database_helper_v2.dart';

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  bool _isLoading = false;

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;

  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await DatabaseHelperV2.instance.getAllSubjects();
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSubject(Subject subject) async {
    try {
      final id = await DatabaseHelperV2.instance.insertSubject(subject);
      _subjects.add(subject.copyWith(id: id));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding subject: $e');
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await DatabaseHelperV2.instance.updateSubject(subject);
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = subject;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating subject: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      await DatabaseHelperV2.instance.deleteSubject(id);
      _subjects.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      rethrow;
    }
  }

  Subject? getSubjectById(int id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
