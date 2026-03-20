/* ----- IMPORT STATEMENTS ----- */
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';                      // for pedometer API
import 'package:permission_handler/permission_handler.dart';    // for requesting permissions
import 'dart:async';                                            // for async functions

class StepCounter extends StatefulWidget {
  const StepCounter({super.key, required this.title});
  final String title;

  @override
  State<StepCounter> createState() => StepCounterState();
}

class StepCounterState extends State<StepCounter> {

  /* ----- VARIABLE DECLARATIONS ----- */
  late Stream<StepCount> _stepCountStream;    // listens for step count
  String _steps = '?';                        // number of steps
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
  void onStepCount(StepCount event) {
    debugPrint('onStepCount: ${event.steps}');
    setState(() {
      _steps = event.steps.toString();
    });
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
      child: Row(
          children: [
            Text(
              '$_steps steps',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
    );
  }
  /* ---- END OF BUILD FUNCTION ---- */

}