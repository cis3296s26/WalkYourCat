import 'package:sqflite/sqflite.dart';
import 'package:walkyourcat/services/database_service.dart';
import 'package:walkyourcat/features/challenges/challenge_item.dart';
import 'achievement_item.dart';

class AchievementsService {
  static final AchievementsService instance = AchievementsService._init();

  AchievementsService._init();

  Future<Database> get database async => await DatabaseService.instance.database;

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