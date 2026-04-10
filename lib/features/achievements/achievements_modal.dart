import 'package:flutter/material.dart';

import 'achievements_ui.dart';

void showAchievementsModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const AchievementsDialog(),
  );
}
