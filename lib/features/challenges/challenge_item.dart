class Challenge {
  final String id;
  final String title;
  final String description;
  final String type; // e.g., 'feeding', 'walking'
  final int targetValue; // e.g., 10000 (steps) or 3 (times)
  final int progress;
  final int rewardCoins;
  final String? metaTarget; // e.g., 'apple' or null for steps

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.progress = 0,
    required this.rewardCoins,
    this.metaTarget,
  });

  bool get isCompleted => progress >= targetValue;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      targetValue: json['targetValue'] as int,
      progress: json['progress'] ?? 0,
      rewardCoins: json['rewardCoins'] as int,
      metaTarget: json['metaTarget'] as String?,
    );
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      targetValue: map['targetValue'] as int,
      progress: map['progress'] as int,
      rewardCoins: map['rewardCoins'] as int,
      metaTarget: map['metaTarget'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'progress': progress,
      'rewardCoins': rewardCoins,
      'metaTarget': metaTarget,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'progress': progress,
      'rewardCoins': rewardCoins,
      'metaTarget': metaTarget,
    };
  }
}
