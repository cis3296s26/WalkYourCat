import 'package:flutter/material.dart';


class LeaderboardDialog extends StatelessWidget {
  const LeaderboardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.9 : 520.0;
    final dialogHeight =
        screenSize.height < 760 ? screenSize.height * 0.78 : 620.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        // child: FutureBuilder<List<Leaderboard>>(
        //   future: LeaderboardsService.instance.getAllLeaderboards(),
        //   builder: (context, snapshot) {
        //     if (snapshot.connectionState != ConnectionState.done) {
        //       return const _LeaderboardLoadingCard();
        //     }

        //     final Leaderboards = snapshot.data ?? <Leaderboard>[];
        //     if (Leaderboards.isEmpty) {
        //       return const _LeaderboardEmptyCard();
        //     }

        //     return _LeaderboardModalCard(Leaderboard: Leaderboard);
        //   },
        // ),
      ),
    );
  }
}