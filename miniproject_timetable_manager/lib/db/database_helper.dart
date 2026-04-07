import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/timetable_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE timetable (
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
  }

  Future<int> insert(Timetable timetable) async {
    final db = await instance.database;
    final map = timetable.toMap();
    map.remove('id'); // Let SQLite auto-generate the ID
    return await db.insert('timetable', map);
  }

  Future<List<Timetable>> getAllTimetables() async {
    final db = await instance.database;
    final result = await db.query('timetable', orderBy: 'id ASC');
    return result.map((json) => Timetable.fromMap(json)).toList();
  }

  Future<List<Timetable>> getTimetablesByDay(String day) async {
    final db = await instance.database;
    final result = await db.query(
      'timetable',
      where: 'day = ?',
      whereArgs: [day],
    );
    return result.map((json) => Timetable.fromMap(json)).toList();
  }

  Future<int> update(Timetable timetable) async {
    final db = await instance.database;
    return await db.update(
      'timetable',
      timetable.toMap(),
      where: 'id = ?',
      whereArgs: [timetable.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'timetable',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
