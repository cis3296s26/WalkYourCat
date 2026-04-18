/* ----- IMPORT STATEMENTS ----- */
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';                      // for pedometer API
import 'dart:async';                                            // for async functions
import 'package:walkyourcat/stepcurrency_manager.dart';         // for managing coins and steps
import 'package:flutter/foundation.dart';
import 'package:walkyourcat/services/geo_service.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({super.key, required this.title, required this.onCoinsUpdated});
  final String title;
  final ValueChanged<int> onCoinsUpdated; // callback to update coins in parent widget

  @override
  State<StepCounter> createState() => StepCounterState();
}

class StepCounterState extends State<StepCounter> {

  /* ----- VARIABLE DECLARATIONS ----- */
  late Stream<StepCount> _stepCountStream;                       // listens for step count
  String _steps = '?';                                           // number of steps
  final StepCurrencyManager currManager = StepCurrencyManager(); // instance of currency manager
  /* -- END OF VARIABLE DECLARATIONS -- */

  /* ------- CHECK ACTIVITY RECOGNITION PERMISSION ------- */
  Future<bool> _checkActivityRecognitionPermission() async {
    return await GeoService.instance.checkActivityRecognitionPermission();
  }
  /* ---- END OF CHECK ACTIVITY RECOGNITION PERMISSION ---- */

  /* ------- INIT PLATFORM STATE ------- */
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // load saved state of coins and steps, and update widget
    await currManager.loadState();
    widget.onCoinsUpdated(currManager.totalCoins);

    if (kIsWeb) {
      debugPrint('Running on Web: Hardware pedometer disabled. Using simulation logic.');
      
      // Calculate and display whatever steps are currently saved in the manager
      int dailySteps = currManager.lastCheckedSteps - currManager.startOfDaySteps;
      if (dailySteps < 0) dailySteps = currManager.lastCheckedSteps;

      if (mounted) {
        setState(() {
          _steps = dailySteps.toString();
        });
      }
      
      // DO NOT REMOVE THIS IT WILL BREAK PLEASE :)
      return; 
    }

    bool granted = await _checkActivityRecognitionPermission();
    if (!granted) {
      debugPrint('Activity Recognition permission not granted');
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }
  /* ---- END OF INIT PLATFORM STATE ---- */

  /* ------------- GETTING STEPS ------------- */
  void onStepCount(StepCount event) async {
    debugPrint('onStepCount: ${event.steps}');

    // process new steps and update coins
    int dailySteps = await currManager.processNewSteps(event.steps);

    setState(() {
      _steps = dailySteps.toString();
    });

    // update coins in parent widget
    widget.onCoinsUpdated(currManager.totalCoins);
  }

  void onStepCountError(error) {
    debugPrint('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }
  /* ----------- END OF GETTING STEPS ----------- */




  /* ------- BUILD FUNCTION ------- */
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      int dailySteps = currManager.lastCheckedSteps - currManager.startOfDaySteps;
      if (dailySteps < 0) dailySteps = currManager.lastCheckedSteps;
      _steps = dailySteps.toString();
    }
    
    return Card(
      color: Colors.deepPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              _steps,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  /* ---- END OF BUILD FUNCTION ---- */

}