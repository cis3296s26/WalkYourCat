// IMPORT STATEMENTS
import 'package:shared_preferences/shared_preferences.dart';    // for storing coin balance persistently

class StepCurrencyManager {
  /* ----- VARIABLE DECLARATIONS ----- */
  int totalCoins = 0;       // total coins earned
  int lastCheckedSteps = 0; // last step count when steps were processed for coins
  int unprocessedSteps = 0; // steps that have been fetched but not processed for coins yet
  /* -- END OF VARIABLE DECLARATIONS -- */


  /// This method loads the saved state of coins and steps from persistent storage.
  Future<void> loadState() async {
    final SharedPreferences prefsL = await SharedPreferences.getInstance();
    totalCoins = prefsL.getInt('totalCoins') ?? 0;
    lastCheckedSteps = prefsL.getInt('lastCheckedSteps') ?? 0;
    unprocessedSteps = prefsL.getInt('unprocessedSteps') ?? 0;
  }

  /// This method saves the current state of coins and steps to persistent storage.
  Future<void> saveState() async {
    final SharedPreferences prefsS = await SharedPreferences.getInstance();
    await prefsS.setInt('totalCoins', totalCoins);
    await prefsS.setInt('lastCheckedSteps', lastCheckedSteps);
    await prefsS.setInt('unprocessedSteps', unprocessedSteps);
  }

  /// TODO: Implement the logic for processing new steps and updating the coin balance accordingly.
  Future<void> processNewSteps(int steps) async {}
}