// food bar (and eventually happiness + health) under the steps/coins widget

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatStatsBar extends StatefulWidget {
  // pass happinessPercent in from main.dart (adi work on it)
  // e.g. CatStatsBar(happinessPercent: _happiness / 100) -- it already affects the food decay rate so no other changes needed
  final double happinessPercent;

  const CatStatsBar({
    super.key,
    this.happinessPercent = 1.0,
  });

  @override
  State<CatStatsBar> createState() => _CatStatsBarState();
}

class _CatStatsBarState extends State<CatStatsBar> {
  double _food = 100.0;
  Timer? _decayTimer;

  static const String _foodKey = 'cat_food_level';
  static const String _lastSavedKey = 'cat_food_last_saved';

  @override
  void initState() {
    super.initState();
    _loadAndDecay();
    _decayTimer = Timer.periodic(const Duration(minutes: 1), (_) => _applyDecay());
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    super.dispose();
  }

  // loads saved food + catches up on any decay that happened while app was closed
  Future<void> _loadAndDecay() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFood = prefs.getDouble(_foodKey) ?? 100.0;
    final lastSavedMs = prefs.getInt(_lastSavedKey) ?? DateTime.now().millisecondsSinceEpoch;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursElapsed = (now - lastSavedMs) / (1000 * 60 * 60);

    // 10 pts/hr if cat is sad, 8 pts/hr otherwise
    final decayRate = widget.happinessPercent < 0.5 ? 10.0 : 8.0;
    final newFood = (savedFood - (hoursElapsed * decayRate)).clamp(0.0, 100.0);

    if (!mounted) return;
    setState(() => _food = newFood);

    await prefs.setDouble(_foodKey, newFood);
    await prefs.setInt(_lastSavedKey, now);
  }

  // called every minute while app is open — 8pts/hr =  about 0.133pts/min
  Future<void> _applyDecay() async {
    final decayRate = widget.happinessPercent < 0.5 ? 10.0 : 8.0;
    final newFood = (_food - decayRate / 60.0).clamp(0.0, 100.0);

    if (!mounted) return;
    setState(() => _food = newFood);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_foodKey, newFood);
    await prefs.setInt(_lastSavedKey, DateTime.now().millisecondsSinceEpoch);
  }

  Color _barColor() {
    if (_food > 60) return const Color(0xFF4CAF50);
    if (_food > 30) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        _StatBar(
          icon: Icons.restaurant,
          label: 'Food',
          value: _food / 100.0,
          color: _barColor(),
        ),

        // happiness bar goes here — just uncomment and pass in your value (you can change the icon/color/label as you like, I just picked something quick for testing)
        // const SizedBox(height: 6),
        // _StatBar(
        //   icon: Icons.sentiment_very_satisfied,
        //   label: 'Happiness',
        //   value: widget.happinessPercent,
        //   color: Color(0xFFE91E8C),
        // ),

      ],
    );
  }
}

// reusable bar widget — icon, label, value (0.0–1.0), color
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}