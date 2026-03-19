import 'package:flutter/material.dart';
import 'package:health/health.dart';        // import the health package

// Global Health instance
final health = Health();

class StepCounter extends StatefulWidget {
  const StepCounter({super.key, required this.title});
  final String title;

  @override
  State<StepCounter> createState() => StepCounterState();
}

class StepCounterState extends State<StepCounter> {
  /* --- VARIABLE DECLARATIONS --- */
  int steps = 6767; // default value for now ---------------- REPLACE FOR WHEN HEALTH API IS IMPLEMENTED !!!!!

  /* ------- STUB FUNCTION ------- */
  /// Gets the number of steps from Health API
  void getSteps() {
    setState(() {
      steps = 6767; // ---------------- REPLACE FOR WHEN HEALTH API IS IMPLEMENTED --------------------- !!!!!
    });
  }
  /* ---- END OF STUB FUNCTION ---- */

  /* ------- BUILD FUNCTION ------- */
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple,
      child: Row(
          children: [
            Text(
              '$steps steps',
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