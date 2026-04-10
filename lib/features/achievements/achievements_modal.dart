import 'package:flutter/material.dart';
import 'achievement_item.dart';
import 'achievements_service.dart';

void showAchievementsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Achievements'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Achievement>>(
          // Point to the new service and model
          future: AchievementsService.instance.getAllAchievements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final achievements = snapshot.data ?? [];
            if (achievements.isEmpty) {
              return const Text('No achievements found yet. Keep going!');
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final item = achievements[index];
                String title = "${item.title} ${item.completionCount}x";                
                
                return ListTile(
                  title: Text(title),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Close')
        ),
      ],
    ),
  );
}