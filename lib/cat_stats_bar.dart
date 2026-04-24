import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatStatsController extends ChangeNotifier {
  static final CatStatsController instance = CatStatsController._init();

  double food = 100.0;
  double health = 100.0;
  double happinessPercent = 1.0;

  static const String _foodKey = 'cat_food_level';
  static const String _healthKey = 'cat_health_level';
  static const String _happinessKey = 'cat_happiness_level';

  static const String _lastSavedTimeKey = 'time_last_saved';

  CatStatsController._init() {
    // Load the values
    loadAndApplyOfflineDecay();
    
    Timer.periodic(const Duration(minutes: 1), (_) => applyDecay());
  }

  /// Saves the current state of the app
  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setDouble(_happinessKey, happinessPercent);
    await prefs.setDouble(_foodKey, food);
    await prefs.setDouble(_healthKey, health);
    await prefs.setInt(_lastSavedTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Unified method to load saved stats and calculate offline decay
  Future<void> loadAndApplyOfflineDecay() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    // fetch saved timestaps
    final lastSavedMs = prefs.getInt(_lastSavedTimeKey) ?? now;

    // calculate elapsed hours since last save for each stat
    final hoursElapsed = (now - lastSavedMs) / (1000 * 60 * 60);

    // fetch saved values
    happinessPercent = prefs.getDouble(_happinessKey) ?? 1.0; 
    food = prefs.getDouble(_foodKey) ?? 100.0;
    health = prefs.getDouble(_healthKey) ?? 100.0;

    // apply decay based on elapsed time
    applyDecay(hoursElapsed: hoursElapsed);
  }

  /// Unified method to apply decay every minute based on current values
  Future<void> applyDecay({double? hoursElapsed}) async {
    /* --- DECAY RATES --- */
    double happinessDecayRate = 0.01; // 1% per minute
    double foodDecayRate = happinessPercent < 0.5 ? 0.16 : 0.13; // Faster decay if unhappy
    double healthDecayRate = food < 30.0 ? 0.33 : 0.0; // Health decays if food is low

    /* --- CASE: user was offline --- */
    if (hoursElapsed != null) {
      happinessPercent = (happinessPercent - (hoursElapsed * happinessDecayRate)).clamp(0.0, 1.0);
      food = (food - (hoursElapsed * foodDecayRate)).clamp(0.0, 100.0);
      health = (health - (hoursElapsed * healthDecayRate)).clamp(0.0, 100.0);
    }
    /* --- CASE: user is online --- */
    else {
      happinessPercent = (happinessPercent - happinessDecayRate).clamp(0.0, 1.0);
      food = (food - foodDecayRate).clamp(0.0, 100.0);
      health = (health - healthDecayRate).clamp(0.0, 100.0);
    }

    // trigger UI update
    notifyListeners();

    // save new values and timestamps
    await _saveCurrentState();
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
    await prefs.setInt(_lastSavedTimeKey, DateTime.now().millisecondsSinceEpoch);
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

  Color _barColor(double value) {
    if (value > 60) return const Color(0xFF4CAF50);
    if (value > 30) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
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
              icon: Icons.restaurant,
              label: 'Food',
              value: controller.food / 100.0,
              color: _barColor(controller.food),
            ),

            _StatBar(
              icon: Icons.health_and_safety,
              label: 'Health',
              value: controller.health / 100.0,
              color: _barColor(controller.health),
            ),
            
            _StatBar(
              icon: Icons.sentiment_very_satisfied,
              label: 'Happiness',
              value: controller.happinessPercent,
              color: _barColor(controller.happinessPercent * 100),
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
            width: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}