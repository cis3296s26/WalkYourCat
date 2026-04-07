import 'package:flutter/material.dart';
import 'challenge_item.dart';
import 'challenges_service.dart';

void showChallengesHistoryModal(BuildContext context) {
  int count = 2; // Example count, replace with actual data if needed
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Challenges History'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Challenge>>(
          future: ChallengesService.instance.fetchChallenges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final challenges = snapshot.data ?? [];
            if (challenges.isEmpty) return const Text('No challenge history found.');

            return ListView.builder(
              shrinkWrap: true,
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final item = challenges[index];
                String title = "${item.title} ${count}x";                
                return ListTile(
                  
                  title: Text(title),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}