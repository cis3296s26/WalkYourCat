import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walkyourcat/cat_stats_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatStatsController Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CatStatsController.instance.revive();
    });

    test('Initial stats should be 100', () async {
      final controller = CatStatsController.instance;

      // Cat was just revived so everything should be at max
      expect(controller.food, 100.0);
      expect(controller.health, 100.0);
      expect(controller.happinessPercent, 1.0);
    });

    test('updateStats should effect values', () async {
      final controller = CatStatsController.instance;
      
      await controller.updateStats(foodAdded: -10, healthAdded: -20);
      
      expect(controller.food, 90.0);
      expect(controller.health, 80.0);
    });

    test('revive should reset stats to 100', () async {
      final controller = CatStatsController.instance;
      
      await controller.updateStats(foodAdded: -50, healthAdded: -50);
      expect(controller.food, 50.0);
      
      await controller.revive();
      
      expect(controller.food, 100.0);
      expect(controller.health, 100.0);
      expect(controller.happinessPercent, 1.0);
    });
  });
}
