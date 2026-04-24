import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:walkyourcat/stepcurrency_manager.dart';
import 'package:walkyourcat/features/leaderboard/leaderboard_item.dart';

class LeaderboardDialog extends StatefulWidget {
  const LeaderboardDialog({super.key});

  @override
  State<LeaderboardDialog> createState() => _LeaderboardDialogState();
}

class _LeaderboardDialogState extends State<LeaderboardDialog> {
  List<Leaderboard> _leaderboardEntries = [];
  bool _isLoading = true;
  Timer? _simulationTimer;

  StepCurrencyManager? _stepManager;

  final Map<String, int> _competitorTargets = {};

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeLeaderboard();
  }

  Future<void> _initializeLeaderboard() async {
    try {
      _stepManager = StepCurrencyManager();
      await _stepManager!.loadState();

      final mySteps = _stepManager!.unprocessedSteps;

      final List<Map<String, dynamic>> competitors = [
        {'id': '1', 'name': 'Bill Harry José', 'target': 13000},
        {'id': '2', 'name': 'John Doe', 'target': 22000},
        {'id': '3', 'name': 'Mary Michael', 'target': 6700},
      ];

      for (var c in competitors) {
        _competitorTargets[c['id'] as String] = c['target'] as int;
      }

      _leaderboardEntries = [
        Leaderboard(id: '1', name: 'Bill Harry José', stepsCount: 0),
        Leaderboard(id: '2', name: 'John Doe', stepsCount: 0),
        Leaderboard(id: '3', name: 'Mary Michael', stepsCount: 0),
        Leaderboard(id: 'me', name: 'You', stepsCount: mySteps),
      ];

      _sortLeaderboard();
      _startSimulation();
    } catch (e) {
      debugPrint('Error loading steps: $e');
      _competitorTargets['1'] = 13000;
      _competitorTargets['2'] = 22000;
      _competitorTargets['3'] = 6700;
      _leaderboardEntries = [
        Leaderboard(id: '1', name: 'Bill Harry José', stepsCount: 0),
        Leaderboard(id: '2', name: 'John Doe', stepsCount: 0),
        Leaderboard(id: '3', name: 'Mary Michael', stepsCount: 0),
        Leaderboard(id: 'me', name: 'You', stepsCount: 0),
      ];
      _sortLeaderboard();
      _startSimulation();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sortLeaderboard() {
    _leaderboardEntries.sort((a, b) => b.stepsCount.compareTo(a.stepsCount));
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSteps();
    });
  }

  Future<void> _updateSteps() async {

    if (!mounted) return;

    try {
      if (_stepManager != null) {
        await _stepManager!.loadState();
        final currentMySteps = _stepManager!.unprocessedSteps;

        setState(() {
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final tomorrowStart = todayStart.add(const Duration(days: 1));
          final totalSecondsInDay =
              tomorrowStart.difference(todayStart).inSeconds.toDouble();
          final secondsPassed = now.difference(todayStart).inSeconds.toDouble();
          final dayProgress = secondsPassed / totalSecondsInDay;

          for (var entry in _leaderboardEntries) {
            if (entry.id == 'me') continue;

            final target = _competitorTargets[entry.id];
            if (target != null) {
              double calculated = target * dayProgress;
              entry.stepsCount = calculated.clamp(0, target).toInt();
            }
          }

          final meEntry = _leaderboardEntries.firstWhere((e) => e.id == 'me');
          meEntry.stepsCount = currentMySteps;

          _sortLeaderboard();
        });
      }
    } catch (e) {
      debugPrint('Error updating steps in real-time: $e');
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

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
        child: _buildLeaderboardContent(),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.leaderboard,
                      size: 28,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track your daily steps and compete with others!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _leaderboardEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _leaderboardEntries[index];
                        final isCurrentUser = entry.id == 'me';
                        final target = _competitorTargets[entry.id];
                        final isAtMax =
                            target != null && entry.stepsCount >= target;

                        return _LeaderboardEntryTile(
                          rank: index + 1,
                          name: entry.name,
                          points: entry.stepsCount,
                          isCurrentUser: isCurrentUser,
                          isAtMax: isAtMax,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEntryTile extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final bool isCurrentUser;
  final bool isAtMax;

  const _LeaderboardEntryTile({
    required this.rank,
    required this.name,
    required this.points,
    this.isCurrentUser = false,
    this.isAtMax = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.blue.shade50
            : (isAtMax ? Colors.grey.shade100 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser
              ? Colors.blue.shade300
              : (isAtMax ? Colors.grey.shade400 : Colors.grey.shade300),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? Colors.amber
                      : (rank == 2
                          ? Colors.grey.shade400
                          : (rank == 3
                              ? Colors.orange.shade300
                              : Colors.blue.shade700)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            '$points steps',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isAtMax ? Colors.grey.shade600 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
