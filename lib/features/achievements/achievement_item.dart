class Achievement {
  final String id;
  final String title;
  final String type;
  final int completionCount;

  Achievement({
    required this.id,
    required this.title,
    required this.type,
    required this.completionCount,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      completionCount: map['completionCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'completionCount': completionCount,
    };
  }
}