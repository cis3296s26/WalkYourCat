import 'package:flutter/material.dart';
import 'challenge_item.dart';
import 'challenges_service.dart';

void showChallengesModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Challenges'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Challenge>>(
          future: ChallengesService.instance.fetchChallenges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final challenges = snapshot.data ?? [];
            if (challenges.isEmpty) return const Text('No challenges found.');

            return ListView.builder(
              shrinkWrap: true,
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final item = challenges[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text('${item.progress} / ${item.targetValue}'),
                  trailing: item.isCompleted ? const Icon(Icons.check, color: Colors.green) : null,
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