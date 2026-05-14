// ──────────────────────────────────────────────
// SchedIQ — Smart Timetable Manager V2
// Database Helper V2 — Extended schema with migrations
// Preserves V1 timetable table, adds V2 tables
// ──────────────────────────────────────────────

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/subject_model.dart';
import '../models/class_entry_model.dart';
import '../models/attendance_model.dart';
import '../models/holiday_model.dart';
import '../models/day_status_model.dart';

class DatabaseHelperV2 {
  static final DatabaseHelperV2 instance = DatabaseHelperV2._init();
  static Database? _database;

  DatabaseHelperV2._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('timetable.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates ALL tables (V1 + V2) on fresh install.
  Future<void> _createDB(Database db, int version) async {
    // V1 table — preserved for backward compatibility
    await db.execute('''
      CREATE TABLE IF NOT EXISTS timetable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        course TEXT NOT NULL,
        faculty TEXT NOT NULL,
        day TEXT NOT NULL,
        time TEXT NOT NULL,
        endTime TEXT NOT NULL,
        location TEXT NOT NULL,
        duration TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // V2 tables
    await _createV2Tables(db);
  }

  /// Migrates from V1 to V2 — adds new tables without touching V1.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        course TEXT NOT NULL,
        faculty TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subjectId INTEGER NOT NULL,
        day TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT NOT NULL,
        duration TEXT NOT NULL,
        FOREIGN KEY (subjectId) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        classId INTEGER NOT NULL,
        date TEXT NOT NULL,
        attended INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (classId) REFERENCES classes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS holidays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS day_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'going'
      )
    ''');
  }

  // ──────────────────────────────────────
  // SUBJECTS
  // ──────────────────────────────────────

  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    final map = subject.toMap();
    map.remove('id');
    return await db.insert('subjects', map);
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final result = await db.query('subjects', orderBy: 'course ASC');
    return result.map((json) => Subject.fromMap(json)).toList();
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final result = await db.query('subjects', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Subject.fromMap(result.first);
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    // CASCADE will delete related classes and attendance
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────
  // CLASSES
  // ──────────────────────────────────────

  Future<int> insertClass(ClassEntry classEntry) async {
    final db = await database;
    final map = classEntry.toMap();
    map.remove('id');
    return await db.insert('classes', map);
  }

  Future<List<ClassEntry>> getAllClasses() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, s.code as subjectCode, s.course as subjectCourse, s.faculty as subjectFaculty
      FROM classes c
      LEFT JOIN subjects s ON c.subjectId = s.id
      ORDER BY c.day, c.startTime
    ''');
    return result.map((json) => ClassEntry.fromMap(json)).toList();
  }

  Future<List<ClassEntry>> getClassesByDay(String day) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, s.code as subjectCode, s.course as subjectCourse, s.faculty as subjectFaculty
      FROM classes c
      LEFT JOIN subjects s ON c.subjectId = s.id
      WHERE c.day = ?
      ORDER BY c.startTime
    ''', [day]);
    return result.map((json) => ClassEntry.fromMap(json)).toList();
  }

  Future<List<ClassEntry>> getClassesBySubject(int subjectId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, s.code as subjectCode, s.course as subjectCourse, s.faculty as subjectFaculty
      FROM classes c
      LEFT JOIN subjects s ON c.subjectId = s.id
      WHERE c.subjectId = ?
      ORDER BY c.day, c.startTime
    ''', [subjectId]);
    return result.map((json) => ClassEntry.fromMap(json)).toList();
  }

  Future<int> updateClass(ClassEntry classEntry) async {
    final db = await database;
    return await db.update(
      'classes',
      classEntry.toMap(),
      where: 'id = ?',
      whereArgs: [classEntry.id],
    );
  }

  Future<int> deleteClass(int id) async {
    final db = await database;
    return await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  // ──────────────────────────────────────
  // ATTENDANCE
  // ──────────────────────────────────────

  Future<int> insertAttendance(AttendanceRecord record) async {
    final db = await database;
    final map = record.toMap();
    map.remove('id');
    return await db.insert('attendance', map);
  }

  Future<List<AttendanceRecord>> getAttendanceByClass(int classId) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      where: 'classId = ?',
      whereArgs: [classId],
      orderBy: 'date DESC',
    );
    return result.map((json) => AttendanceRecord.fromMap(json)).toList();
  }

  Future<AttendanceRecord?> getAttendanceForClassOnDate(
      int classId, String date) async {
    final db = await database;
    final result = await db.query(
      'attendance',
      where: 'classId = ? AND date = ?',
      whereArgs: [classId, date],
    );
    if (result.isEmpty) return null;
    return AttendanceRecord.fromMap(result.first);
  }

  Future<int> updateAttendance(AttendanceRecord record) async {
    final db = await database;
    return await db.update(
      'attendance',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await database;
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  /// Get aggregated attendance per subject.
  Future<List<SubjectAttendance>> getSubjectAttendanceSummary() async {
    final db = await database;
    final subjects = await getAllSubjects();
    final List<SubjectAttendance> summaries = [];

    for (final subject in subjects) {
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN a.attended = 1 THEN 1 ELSE 0 END) as attended,
          SUM(CASE WHEN a.attended = 2 THEN 1 ELSE 0 END) as od
        FROM attendance a
        INNER JOIN classes c ON a.classId = c.id
        WHERE c.subjectId = ?
      ''', [subject.id]);

      final total = (result.first['total'] as int?) ?? 0;
      final attended = (result.first['attended'] as int?) ?? 0;
      final od = (result.first['od'] as int?) ?? 0;

      summaries.add(SubjectAttendance(
        subjectId: subject.id!,
        code: subject.code,
        course: subject.course,
        faculty: subject.faculty,
        totalClasses: total,
        attendedClasses: attended,
        odClasses: od,
      ));
    }

    return summaries;
  }

  // ──────────────────────────────────────
  // HOLIDAYS
  // ──────────────────────────────────────

  Future<int> insertHoliday(Holiday holiday) async {
    final db = await database;
    final map = holiday.toMap();
    map.remove('id');
    return await db.insert('holidays', map);
  }

  Future<List<Holiday>> getAllHolidays() async {
    final db = await database;
    final result = await db.query('holidays', orderBy: 'startDate ASC');
    return result.map((json) => Holiday.fromMap(json)).toList();
  }

  Future<int> updateHoliday(Holiday holiday) async {
    final db = await database;
    return await db.update(
      'holidays',
      holiday.toMap(),
      where: 'id = ?',
      whereArgs: [holiday.id],
    );
  }

  Future<int> deleteHoliday(int id) async {
    final db = await database;
    return await db.delete('holidays', where: 'id = ?', whereArgs: [id]);
  }

  /// Check if a given date falls on any holiday.
  Future<bool> isHoliday(DateTime date) async {
    final holidays = await getAllHolidays();
    return holidays.any((h) => h.containsDate(date));
  }

  // ──────────────────────────────────────
  // DAY STATUS
  // ──────────────────────────────────────

  Future<int> setDayStatus(DayStatus dayStatus) async {
    final db = await database;
    // Use INSERT OR REPLACE since date is UNIQUE
    final map = dayStatus.toMap();
    map.remove('id');
    return await db.insert(
      'day_status',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DayStatus?> getDayStatus(String date) async {
    final db = await database;
    final result = await db.query(
      'day_status',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (result.isEmpty) return null;
    return DayStatus.fromMap(result.first);
  }

  Future<List<DayStatus>> getAllDayStatuses() async {
    final db = await database;
    final result = await db.query('day_status', orderBy: 'date DESC');
    return result.map((json) => DayStatus.fromMap(json)).toList();
  }

  // ──────────────────────────────────────
  // UTILITY
  // ──────────────────────────────────────

  Future<int> getClassCountForDay(String day) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM classes WHERE day = ?',
      [day],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, int>> getWeeklySummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT day, COUNT(*) as count FROM classes GROUP BY day
    ''');
    final Map<String, int> summary = {};
    for (final row in result) {
      summary[row['day'] as String] = (row['count'] as int?) ?? 0;
    }
    return summary;
  }

  Future<int> getTotalClassCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM classes');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
