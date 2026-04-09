/* ----- IMPORT STATEMENTS ----- */
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';                      // for pedometer API
import 'package:permission_handler/permission_handler.dart';    // for requesting permissions
import 'dart:async';                                            // for async functions
import 'package:walkyourcat/stepcurrency_manager.dart';         // for managing coins and steps

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
    bool granted = await Permission.activityRecognition.isGranted;

    if (!granted) {
      granted = await Permission.activityRecognition.request() ==
          PermissionStatus.granted;
    }

    return granted;
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