class Leaderboard {
  final String id;
  final int stepsCount;

  Leaderboard({
    required this.id,
    required this.stepsCount,
  });

  factory Leaderboard.fromMap(Map<String, dynamic> map) {
    return Leaderboard(
      id: map['id'] as String,
      stepsCount: map['stepsCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stepsCount': stepsCount,
    };
  }
}