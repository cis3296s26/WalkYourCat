import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:walkyourcat/features/challenges/challenge_item.dart';
import 'achievement_item.dart';

class AchievementsService {
  static final AchievementsService instance = AchievementsService._init();
  static Database? _database;

  AchievementsService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('achievements_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        completionCount INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> recordChallengeCompletion(Challenge challenge) async {
    final db = await instance.database;

    await db.rawInsert('''
      INSERT INTO achievements (id, title, type, completionCount)
      VALUES (?, ?, ?, 1)
      ON CONFLICT(id) DO UPDATE SET 
      completionCount = completionCount + 1,
      title = excluded.title, 
      type = excluded.type
    ''', [challenge.id, challenge.title, challenge.type]);
  }

  /// Retrieves all historical achievements
  Future<List<Achievement>> getAllAchievements() async {
    final db = await instance.database;
    final result = await db.query('achievements', orderBy: 'completionCount DESC');
    return result.map((json) => Achievement.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}