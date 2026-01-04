import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_progress.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'candlestick_progress.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE progress(
            pattern_id TEXT PRIMARY KEY,
            attempts INTEGER,
            correct INTEGER,
            streak INTEGER,
            last_practiced TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveProgress(UserProgress progress) async {
    final db = await database;
    await db.insert(
      'progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProgress?> getProgress(String patternId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progress',
      where: 'pattern_id = ?',
      whereArgs: [patternId],
    );

    if (maps.isEmpty) return null;
    return UserProgress.fromMap(maps.first);
  }

  Future<List<UserProgress>> getAllProgress() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('progress');
    return maps.map((e) => UserProgress.fromMap(e)).toList();
  }
}
