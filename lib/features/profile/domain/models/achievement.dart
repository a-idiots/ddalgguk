class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final AchievementType type;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isUnlocked,
    required this.progress,
    required this.type,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      isUnlocked: json['isUnlocked'] as bool,
      progress: (json['progress'] as num).toDouble(),
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AchievementType.drinking,
      ),
    );
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    bool? isUnlocked,
    double? progress,
    AchievementType? type,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'isUnlocked': isUnlocked,
      'progress': progress,
      'type': type.toString(),
    };
  }
}

enum AchievementType {
  drinking, // 음주 관련 업적
  sober, // 금주 관련 업적
  tracking, // 기록 관련 업적
  social, // 소셜 관련 업적
  special, // 특별 업적
}
