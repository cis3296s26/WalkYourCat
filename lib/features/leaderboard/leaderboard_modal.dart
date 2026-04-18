import 'package:flutter/material.dart';

import 'leaderboard_ui.dart';

void showLeaderboardModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const LeaderboardDialog(),
  );
}