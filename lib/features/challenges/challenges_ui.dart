import 'package:flutter/material.dart';
import 'package:walkyourcat/features/achievements/achievements_ui.dart';

import 'challenge_item.dart';
import 'challenges_service.dart';

// entry point
void showChallengesModal(
  BuildContext context, {
  VoidCallback? onCoinsAdded,
  int initialTab = 0,
}) =>
    showDialog(
      context: context,
      builder: (_) => _ChallengesDialog(
        onCoinsAdded: onCoinsAdded,
        initialTab: initialTab,
      ),
    );

//theme
const _kPurple = Color(0xFF7C3AED);
const _kGreen = Color(0xFF16A34A);
const _kBg = Color(0xFFF8F7FF);

// per type config (icons, colors)
class _TypeConfig {
  final String icon;
  final LinearGradient gradient;
  final Color accent;
  const _TypeConfig(
      {required this.icon, required this.gradient, required this.accent});
}

const _kTypeConfig = <String, _TypeConfig>{
  'walking': _TypeConfig(
    icon: '🚶',
    gradient: LinearGradient(
      colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accent: Color(0xFF7C3AED),
  ),
  'feeding': _TypeConfig(
    icon: '🍽️',
    gradient: LinearGradient(
      colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accent: Color(0xFFD97706),
  ),
  'petting': _TypeConfig(
    icon: '🐾',
    gradient: LinearGradient(
      colors: [Color(0xFFFFE4E6), Color(0xFFFFF1F2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accent: Color(0xFFE11D48),
  ),
};

_TypeConfig _configFor(String type) =>
    _kTypeConfig[type] ??
    const _TypeConfig(
      icon: '⭐',
      gradient: LinearGradient(colors: [Color(0xFFF3F4F6), Color(0xFFFFFFFF)]),
      accent: Color(0xFF6B7280),
    );

//dialog
class _ChallengesDialog extends StatefulWidget {
  final VoidCallback? onCoinsAdded;
  final int initialTab;

  const _ChallengesDialog({
    this.onCoinsAdded,
    this.initialTab = 0,
  });

  @override
  State<_ChallengesDialog> createState() => _ChallengesDialogState();
}

class _ChallengesDialogState extends State<_ChallengesDialog> {
  late final Future<List<Challenge>> _future =
      ChallengesService.instance.fetchChallenges();

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
        child: DefaultTabController(
          length: 2,
          initialIndex: widget.initialTab,
          child: Material(
            color: _kBg,
            borderRadius: const BorderRadius.all(Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _PurrsuitsHeader(),
                Container(
                  color: Colors.white.withValues(alpha: 0.45),
                  child: const TabBar(
                    indicatorColor: _kPurple,
                    labelColor: Color(0xFF1C1028),
                    unselectedLabelColor: Color(0xFF8A7C72),
                    labelStyle: TextStyle(fontWeight: FontWeight.w800),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.flag_rounded, size: 18),
                        text: 'Challenges',
                      ),
                      Tab(
                        icon: Icon(Icons.emoji_events_rounded, size: 18),
                        text: 'Achievements',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ChallengesTab(future: _future),
                      const AchievementsContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PurrsuitsHeader extends StatelessWidget {
  const _PurrsuitsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purrsuits',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C1028),
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Complete tasks. Track your wins.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A7C72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF8A7C72),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab({required this.future});

  final Future<List<Challenge>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Challenge>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _Loading();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _Empty(
            message: 'No challenges today — check back tomorrow!',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ActiveChallengeCard(challenge: items[i]),
        );
      },
    );
  }
}

//active challenge card
class _ActiveChallengeCard extends StatelessWidget {
  final Challenge challenge;
  const _ActiveChallengeCard({required this.challenge});

  String get _stepLabel {
    if (challenge.type == 'walking') {
      final k = challenge.targetValue / 1000;
      return '${k % 1 == 0 ? k.toInt() : k}k steps';
    }
    return '×${challenge.targetValue}';
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _configFor(challenge.type);
    final progress =
        (challenge.progress / challenge.targetValue).clamp(0.0, 1.0);
    final done = challenge.isCompleted;
    final accent = done ? _kGreen : cfg.accent;

    return Container(
      decoration: BoxDecoration(
        gradient: cfg.gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                  child: Text(cfg.icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + done badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(challenge.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1028),
                            )),
                      ),
                      if (done)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 12, color: _kGreen),
                              SizedBox(width: 3),
                              Text('Done',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(challenge.description,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3)),
                  const SizedBox(height: 10),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Progress count + coin reward
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${challenge.progress} / ${challenge.targetValue}  ·  $_stepLabel',
                        style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600),
                      ),
                      _CoinBadge(coins: challenge.rewardCoins),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// shared badge for showing coin rewards
class _CoinBadge extends StatelessWidget {
  final int coins;
  const _CoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE047), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Text('+$coins',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF854D0E))),
          ],
        ),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2.5),
        ),
      );
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      );
}
