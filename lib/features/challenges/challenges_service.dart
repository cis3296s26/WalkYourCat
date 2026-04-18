import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:walkyourcat/core/services/database_service.dart';
import 'challenge_item.dart';
import 'package:walkyourcat/features/achievements/achievements_service.dart';
import 'package:walkyourcat/stepcurrency_manager.dart';

class ChallengesService {
  static final ChallengesService instance = ChallengesService._init();

  ChallengesService._init();

  final String _jsonPath = 'assets/challenges.json';

  Future<Database> get database async => await DatabaseService.instance.database;

  /// Get active challenges, pulling from templated JSON if DB is empty
  Future<List<Challenge>> fetchChallenges() async {
    final db = await instance.database;
    final result = await db.query('active_challenges');
    
    if (result.isEmpty) {
      final generated = await _generateDailyChallenges();
      for (var c in generated) {
        await db.insert('active_challenges', c.toMap());
      }
      return generated;
    }
    
    return result.map((json) => Challenge.fromMap(json)).toList();
  }

  /// Randomizes attributes based on the template
  Future<List<Challenge>> _generateDailyChallenges() async {
    // Fetch the actual json challenge strings
    final jsonString = await rootBundle.loadString(_jsonPath);
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final List<dynamic> templates = jsonMap['challenges'];
    
    final random = Random();
    List<Challenge> generated = [];
    
    for (var template in templates) {
      String id = template['id'];
      String title = template['title'];
      String description = template['description'];
      String type = template['type'];
      int targetValue = template['targetValue'];
      int rewardCoins = template['rewardCoins'];
      String? metaTarget = template['metaTarget'];

      if (id == 'chal_001') { // Walking
        targetValue = 10000; // 10ksteps
        rewardCoins = 1000;
        description = "Walk ${targetValue} steps to keep your cat company.";
        debugPrint("[CHAL] Generated Walking Challenge: $description");
      } 
      else if (id == 'chal_002') { // Feeding
        // get food items from shop_items.json
        final itemsJsonString = await rootBundle.loadString('assets/shop_items.json');
        final itemsJson = json.decode(itemsJsonString) as Map<String, dynamic>;
        final foods = (itemsJson['items'] as List<dynamic>).where((item) => item['tag'] == 'food').toList();

        final selectedFood = foods[random.nextInt(foods.length)] as Map<String, dynamic>;
        targetValue = 1 + random.nextInt(4); // 1 - 4
        rewardCoins = targetValue * 15;
        metaTarget = (selectedFood['id'] as int).toString();
        description = "Feed your cat ${selectedFood['name']} $targetValue times.";
        debugPrint("[CHAL] Generated Feeding Challenge: $description");
      }
      else if (id == 'chal_003') { // Petting
        targetValue = 5 + random.nextInt(16); // 5 - 20
        rewardCoins = targetValue * 5;
        metaTarget = targetValue.toString();
        description = "Pet your cat $targetValue times.";
        debugPrint("[CHAL] Generated Petting Challenge: $description");
      }

      generated.add(Challenge(
        id: id,
        title: title,
        description: description,
        type: type,
        targetValue: targetValue,
        progress: 0,
        rewardCoins: rewardCoins,
        metaTarget: metaTarget,
      ));
    }
    
    return generated;
  }

  /// Increase progress for challenges of a certain type
  Future<void> addProgress(String type, int amount, {String? metaTargetFilter}) async {
    final db = await instance.database;
    final allChallenges = await fetchChallenges();
    
    for (var c in allChallenges) {
      if (c.type == type && !c.isCompleted) {
        // Only increase progress if metaTargets match or is null
        if (metaTargetFilter != null && c.metaTarget != null) {
          if (c.metaTarget != metaTargetFilter) continue;
        }

        int newProgress = c.progress + amount;
        bool justCompleted = newProgress >= c.targetValue;

        if (newProgress > c.targetValue) newProgress = c.targetValue;
        
        await db.update(
          'active_challenges',
          {'progress': newProgress},
          where: 'id = ?',
          whereArgs: [c.id],
        );

        if (justCompleted) {
          AchievementsService.instance.recordChallengeCompletion(c);
          await StepCurrencyManager().addCoins(c.rewardCoins);
        }
      }
    }
  }

  /// Get challenges by type
  Future<List<Challenge>> getChallengesByType(String type) async {
    final allChallenges = await fetchChallenges();
    return allChallenges.where((c) => c.type == type).toList();
  }

  /// Called daily? IDK ourimplementation for this
  Future<void> clearChallenges() async {
    final db = await instance.database;
    await db.delete('active_challenges');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
