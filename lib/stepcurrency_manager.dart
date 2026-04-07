// IMPORT STATEMENTS
import 'package:shared_preferences/shared_preferences.dart'; // for storing coin balance persistently
import 'package:walkyourcat/features/challenges/challenges_service.dart';

class StepCurrencyManager {
  /* ----- VARIABLE DECLARATIONS ----- */
  int totalCoins = 0; // total coins earned
  int lastCheckedSteps = 0; // last step count when steps were processed for coins
  int unprocessedSteps = 0; // steps that have been fetched but not processed for coins yet

  int startOfDaySteps = 0;
  int lastDate = 0;
  /* -- END OF VARIABLE DECLARATIONS -- */

  /* ----- LOAD & SAVE FUNCTIONS ----- */
  /// This method loads the saved state of coins and steps from persistent storage.
  Future<void> loadState() async {
    final SharedPreferences prefsL = await SharedPreferences.getInstance();
    totalCoins = prefsL.getInt('totalCoins') ?? totalCoins;
    lastCheckedSteps = prefsL.getInt('lastCheckedSteps') ?? lastCheckedSteps;
    unprocessedSteps = prefsL.getInt('unprocessedSteps') ?? unprocessedSteps;

    lastDate = prefsL.getInt('lastDay') ?? DateTime.now().day;
  }

  /// This method saves the current state of coins and steps to persistent storage.
  Future<void> saveState() async {
    final SharedPreferences prefsS = await SharedPreferences.getInstance();
    await prefsS.setInt('totalCoins', totalCoins);
    await prefsS.setInt('lastCheckedSteps', lastCheckedSteps);
    await prefsS.setInt('unprocessedSteps', unprocessedSteps);

    await prefsS.setInt('lastDay', lastDate);
  }
  /* --- END OF LOAD & SAVE FUNCTIONS --- */

  /// This method processes new steps and updates the coin balance accordingly.
  Future<int> processNewSteps(int steps) async {
    /* --- FOR DAILY STEP RESET --- */
    // get current day
    int currentDay = DateTime.now().day;

    // check if a new day to reset
    if (currentDay != lastDate) {
      startOfDaySteps = steps; // Set new baseline
      lastDate = currentDay;   // Update the day
      unprocessedSteps = 0; 
      await ChallengesService.instance.clearChallenges(); // Reset daily challenges
    }
    /* --- END OF DAILY STEP RESET --- */

    /* --- variables --- */
    int newSteps = 0; // initialize new steps variable

    // check if steps were added since we last checked
    if (steps >= lastCheckedSteps) {
      newSteps = steps - lastCheckedSteps;
    } else {
      // case: for when the step count resets, treat all steps as new
      newSteps = steps;
      startOfDaySteps = 0; 
    }

    // update last checked steps and unprocessed steps
    lastCheckedSteps = steps;
    unprocessedSteps += newSteps;

    // convert steps to coins (10 coins per 100 steps)
    if (unprocessedSteps >= 100) {
      int coinsEarned = (unprocessedSteps / 100).floor() * 10;
      totalCoins += coinsEarned;

      // keep remainder for next processing
      unprocessedSteps = unprocessedSteps % 100;
    }

    // save the updated state
    await saveState();

    // calculate daily steps for display
    int dailySteps = steps - startOfDaySteps;
    if (dailySteps < 0) dailySteps = steps;

    // Update challenge progress with the new steps taken
    await ChallengesService.instance.addProgress('walking', 1);

    return dailySteps;
  }

  Future<int> getCoinBalance() async {
    await loadState(); // ensure we have the latest state loaded
    return totalCoins;
  }

  Future<void> setCoinBalance(int coins) async {
    await loadState();
    totalCoins = coins;
    await saveState();
  }
}
