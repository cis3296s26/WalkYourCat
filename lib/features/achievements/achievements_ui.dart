import 'package:flutter/material.dart';

import 'achievement_item.dart';
import 'achievements_service.dart';

class AchievementsDialog extends StatelessWidget {
  const AchievementsDialog({super.key});

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
        child: Material(
          color: const Color(0xFFFFFBF6),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: const Column(
            children: [
              _AchievementsHeader(),
              Expanded(child: AchievementsContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class AchievementsContent extends StatelessWidget {
  const AchievementsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Achievement>>(
      future: AchievementsService.instance.getAllAchievements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AchievementsLoadingCard();
        }

        final achievements = snapshot.data ?? <Achievement>[];
        if (achievements.isEmpty) {
          return const _AchievementsEmptyCard();
        }

        return _AchievementsGrid(achievements: achievements);
      },
    );
  }
}

class _AchievementStyle {
  final String icon;
  final Color accent;
  final Color soft;
  final LinearGradient glow;

  const _AchievementStyle({
    required this.icon,
    required this.accent,
    required this.soft,
    required this.glow,
  });
}

const Map<String, _AchievementStyle> _achievementStyles = {
  'walking': _AchievementStyle(
    icon: '🚶',
    accent: Color(0xFF7C3AED),
    soft: Color(0xFFF1EBFF),
    glow: LinearGradient(
      colors: [Color(0xFFEDE9FE), Color(0xFFF8F5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  'feeding': _AchievementStyle(
    icon: '🍽️',
    accent: Color(0xFFD97706),
    soft: Color(0xFFFFF1D8),
    glow: LinearGradient(
      colors: [Color(0xFFFFE8BE), Color(0xFFFFF8E8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  'petting': _AchievementStyle(
    icon: '🐾',
    accent: Color(0xFFE11D48),
    soft: Color(0xFFFFE6EC),
    glow: LinearGradient(
      colors: [Color(0xFFFFD9E2), Color(0xFFFFF2F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
};

_AchievementStyle _styleFor(String type) {
  return _achievementStyles[type] ??
      const _AchievementStyle(
        icon: '⭐',
        accent: Color(0xFF607D8B),
        soft: Color(0xFFECEFF1),
        glow: LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
}

class _AchievementsLoadingCard extends StatelessWidget {
  const _AchievementsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _AchievementsEmptyCard extends StatelessWidget {
  const _AchievementsEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: Colors.amber.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'No achievements yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete daily challenges and your wins will start showing up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.83,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _AchievementCard(achievement: achievements[index]);
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(achievement.type);
    final titleColor = const Color(0xFF3E2723);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: style.glow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: style.accent.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      style.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: style.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${achievement.completionCount}x',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: style.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsHeader extends StatelessWidget {
  const _AchievementsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFE7A100),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F1F17),
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your completed challenge history',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A7C72),
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
