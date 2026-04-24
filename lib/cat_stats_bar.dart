import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatStatsController extends ChangeNotifier {
  static final CatStatsController instance = CatStatsController._init();

  double food = 100.0;
  double health = 100.0;
  double happinessPercent = 1.0;

  static const String _foodKey = 'cat_food_level';
  static const String _lastSavedKey = 'cat_food_last_saved';

  static const String _healthKey = 'cat_health_level';
  static const String _lastSavedHealthKey = 'cat_health_last_saved';

  static const String _happinessKey = 'cat_happiness_level';
  static const String _lastSavedHappinessKey = 'cat_happiness_last_saved';

  CatStatsController._init() {
    // Load the values
    _foodLoadAndDecay();
    _healthLoadAndDecay();
    _happinessLoadAndDecay();

    // Decay timers
    Timer.periodic(const Duration(minutes: 1), (_) => _applyDecay());
  }

  /* Decay Logic */
  Future<void> _foodLoadAndDecay() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFood = prefs.getDouble(_foodKey) ?? 100.0;
    final lastSavedMs = prefs.getInt(_lastSavedKey) ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursElapsed = (now - lastSavedMs) / (1000 * 60 * 60);

    final decayRate = happinessPercent < 0.5 ? 10.0 : 8.0;
    food = (savedFood - (hoursElapsed * decayRate)).clamp(0.0, 100.0);

    notifyListeners(); // Tells the UI to redraw

    await prefs.setDouble(_foodKey, food);
    await prefs.setInt(_lastSavedKey, now);
  }

  Future<void> _healthLoadAndDecay() async {
    final prefs = await SharedPreferences.getInstance();

    final savedHealth = prefs.getDouble(_healthKey) ?? 100.0;
    final lastSavedMs = prefs.getInt(_lastSavedHealthKey) ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursElapsed = (now - lastSavedMs) / (1000 * 60 * 60);

    final decayRate = food < 30.0 ? 20.0 : 0.0;
    health = (savedHealth - (hoursElapsed * decayRate)).clamp(0.0, 100.0);

    notifyListeners();

    await prefs.setDouble(_healthKey, health);
    await prefs.setInt(_lastSavedHealthKey, now);
  }

  Future<void> _happinessLoadAndDecay() async {
    final prefs = await SharedPreferences.getInstance();

    final savedHappiness = prefs.getDouble(_happinessKey) ?? 100.0;
    final lastSavedMs = prefs.getInt(_lastSavedHappinessKey) ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursElapsed = (now - lastSavedMs) / (1000 * 60 * 60);

    happinessPercent = (savedHappiness - (hoursElapsed / 10)).clamp(0.0, 1.0);

    notifyListeners();

    await prefs.setDouble(_happinessKey, happinessPercent);
    await prefs.setInt(_lastSavedHappinessKey, now);
  }

  Future<void> _applyDecay() async {
    await _applyFoodDecay();
    await _applyHealthDecay();
    await _applyHappinessDecay();
  }

  Future<void> _applyFoodDecay() async {
    final decayRate = happinessPercent < 0.5 ? 10.0 : 8.0;
    food = (food - decayRate / 60.0).clamp(0.0, 100.0);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_foodKey, food);
    await prefs.setInt(_lastSavedKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _applyHealthDecay() async {
    final decayRate = food < 30.0 ? 20.0 : 0.0;
    health = (health - decayRate / 60.0).clamp(0.0, 100.0);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_healthKey, health);
    await prefs.setInt( _lastSavedHealthKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _applyHappinessDecay() async {
    happinessPercent = (happinessPercent - 0.01).clamp(0.0, 1.0);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_happinessKey, happinessPercent);
    await prefs.setInt(_lastSavedHappinessKey, DateTime.now().millisecondsSinceEpoch);
  }

  /* Inventory Item Use */
  Future<void> updateStats({int? foodAdded, int? healthAdded, int? happinessAdded}) async {
    if (foodAdded != null) {
      food = (food + foodAdded).clamp(0.0, 100.0); // Clamped so progress bar doesn't crash if > 100
    }
    if (healthAdded != null) {
      health = (health + healthAdded).clamp(0.0, 100.0);
    }
    if (happinessAdded != null) {
      happinessPercent = (happinessPercent + (happinessAdded / 100)).clamp(0.0, 1.0);
    }

    debugPrint("Stats are now: Food: $food, Health: $health");
    notifyListeners(); // Force the UI to update

    // Save the new stat boost immediately so closing the app doesn't lose it
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_foodKey, food);
    await prefs.setDouble(_healthKey, health);
  }

  /// Resets all stats to 100. Used for reviving the cat.
  Future<void> revive() async {
    debugPrint("[STAT]: REVIVE() WAS CALLED");
    food = 100.0;
    health = 100.0;
    happinessPercent = 1.0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_foodKey, food);
    await prefs.setDouble(_healthKey, health);
    await prefs.setDouble(_happinessKey, happinessPercent);
    await prefs.setInt(_lastSavedKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_lastSavedHealthKey, DateTime.now().millisecondsSinceEpoch);
  }
}

/* UI Widget */
class CatStatsBar extends StatelessWidget {
  const CatStatsBar({super.key});

  // Legacy wrapper for old code
  static Future<void> updateStats({int? food, int? health, int? happiness}) {
    return CatStatsController.instance.updateStats(
      foodAdded: food,
      healthAdded: health,
      happinessAdded: happiness,
    );
  }

  @override
  Widget build(BuildContext context) {
    // redraw whenever notifyListeners() is called inside the controller
    return ListenableBuilder(
      listenable: CatStatsController.instance,
      builder: (context, child) {
        final controller = CatStatsController.instance;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatBar(
              icon: Icons.health_and_safety,
              label: 'Health',
              value: controller.health / 100.0,
              color: Color.fromRGBO(112, 236, 70, 1),
            ),
            _StatBar(
              icon: Icons.restaurant,
              label: 'Food',
              value: controller.food / 100.0,
              color: Color.fromRGBO(234, 126, 54, 1),
            ),
            _StatBar(
              icon: Icons.sentiment_very_satisfied,
              label: 'Happiness',
              value: controller.happinessPercent,
              color: Color.fromRGBO(239, 204, 60, 1),
            ),
          ],
        );
      },
    );
  }
}

/* UI Component */
class _StatBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _StatBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(0, 0, 0, 0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(0, 0, 0, 0), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black, size: 15),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Container(
              height: 14,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color, width: 1.8),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
