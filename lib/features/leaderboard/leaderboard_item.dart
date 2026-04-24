class Leaderboard {
  final String id;
  final String name;
  int stepsCount;

  Leaderboard({
    required this.id,
    required this.name,
    required this.stepsCount,
  });

  factory Leaderboard.fromMap(Map<String, dynamic> map) {
    return Leaderboard(
      id: map['id'] as String,
      name: map['name'] as String,
      stepsCount: map['stepsCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stepsCount': stepsCount,
    };
  }
}