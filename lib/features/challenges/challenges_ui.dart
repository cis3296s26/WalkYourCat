import 'package:flutter/material.dart';
import 'challenge_item.dart';
import 'challenges_service.dart';

// entry point
void showChallengesModal(BuildContext context, {VoidCallback? onCoinsAdded}) =>
    showDialog(context: context, builder: (_) => _ChallengesDialog(onCoinsAdded: onCoinsAdded));

//theme
const _kPurple = Color(0xFF7C3AED);
const _kGreen  = Color(0xFF16A34A);
const _kBg     = Color(0xFFF8F7FF);

// per type config (icons, colors)
class _TypeConfig {
  final String icon;
  final LinearGradient gradient;
  final Color accent;
  const _TypeConfig({required this.icon, required this.gradient, required this.accent});
}

const _kTypeConfig = <String, _TypeConfig>{
  'walking': _TypeConfig(
    icon: '🚶',
    gradient: LinearGradient(
      colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    accent: Color(0xFF7C3AED),
  ),
  'feeding': _TypeConfig(
    icon: '🍽️',
    gradient: LinearGradient(
      colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    accent: Color(0xFFD97706),
  ),
  'petting': _TypeConfig(
    icon: '🐾',
    gradient: LinearGradient(
      colors: [Color(0xFFFFE4E6), Color(0xFFFFF1F2)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
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
  const _ChallengesDialog({this.onCoinsAdded});
  @override
  State<_ChallengesDialog> createState() => _ChallengesDialogState();
}

class _ChallengesDialogState extends State<_ChallengesDialog> {
  late final Future<List<Challenge>> _future =
      ChallengesService.instance.fetchChallenges();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: _kBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('Daily Challenges',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1028),
                  letterSpacing: -0.8,
                )),
            const SizedBox(height: 2),
            Text('Complete tasks. Earn coins.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 48,
              decoration: BoxDecoration(
                  color: _kPurple, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),

            // List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.58,
              ),
              child: FutureBuilder<List<Challenge>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _Loading();
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const _Empty(
                        message: 'No challenges today — check back tomorrow!');
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ActiveChallengeCard(challenge: items[i]),
                  );
                },
              ),
            ),

            // Close
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _kPurple,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
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
    final progress = (challenge.progress / challenge.targetValue).clamp(0.0, 1.0);
    final done = challenge.isCompleted;
    final accent = done ? _kGreen : cfg.accent;

    return Container(
      decoration: BoxDecoration(
        gradient: cfg.gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: accent.withOpacity(0.08),
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
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: accent.withOpacity(0.15),
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
                            color: _kGreen.withOpacity(0.12),
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
                      backgroundColor: Colors.white.withOpacity(0.6),
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