class ProfileStats {
  const ProfileStats({
    required this.thisMonthDrunkDays,
    required this.currentAlcoholInBody,
    required this.timeToSober,
    required this.statusMessage,
    required this.breakdown,
    this.consecutiveDrinkingDays = 0,
    this.consecutiveSoberDays = 0,
    this.todayDrunkLevel = 0,
    this.thisMonthDrinkingCount = 0,
  });

  factory ProfileStats.empty() {
    return ProfileStats(
      thisMonthDrunkDays: 0,
      currentAlcoholInBody: 0,
      timeToSober: 0,
      statusMessage: '건강한 상태입니다',
      breakdown: AlcoholBreakdown.empty(),
      consecutiveDrinkingDays: 0,
      consecutiveSoberDays: 0,
      todayDrunkLevel: 0,
      thisMonthDrinkingCount: 0,
    );
  }

  final int thisMonthDrunkDays; // 0-100
  final double currentAlcoholInBody; // in grams
  final double timeToSober; // in hours
  final String statusMessage;
  final AlcoholBreakdown breakdown;
  final int consecutiveDrinkingDays;
  final int consecutiveSoberDays;
  final int todayDrunkLevel;
  final int thisMonthDrinkingCount;

  ProfileStats copyWith({
    int? currentDrunkLevel,
    double? currentAlcoholInBody,
    double? timeToSober,
    String? statusMessage,
    AlcoholBreakdown? breakdown,
    int? consecutiveDrinkingDays,
    int? consecutiveSoberDays,
    int? todayDrunkLevel,
    int? thisMonthDrinkingCount,
  }) {
    return ProfileStats(
      thisMonthDrunkDays: currentDrunkLevel ?? thisMonthDrunkDays,
      currentAlcoholInBody: currentAlcoholInBody ?? this.currentAlcoholInBody,
      timeToSober: timeToSober ?? this.timeToSober,
      statusMessage: statusMessage ?? this.statusMessage,
      breakdown: breakdown ?? this.breakdown,
      consecutiveDrinkingDays:
          consecutiveDrinkingDays ?? this.consecutiveDrinkingDays,
      consecutiveSoberDays: consecutiveSoberDays ?? this.consecutiveSoberDays,
      todayDrunkLevel: todayDrunkLevel ?? this.todayDrunkLevel,
      thisMonthDrinkingCount:
          thisMonthDrinkingCount ?? this.thisMonthDrinkingCount,
    );
  }
}

class AlcoholBreakdown {
  const AlcoholBreakdown({
    required this.alcoholRemaining,
    required this.progressPercentage,
    this.lastDrinkTime,
    this.estimatedSoberTime,
  });

  factory AlcoholBreakdown.empty() {
    return const AlcoholBreakdown(alcoholRemaining: 0, progressPercentage: 0);
  }

  final double alcoholRemaining; // in grams
  final double progressPercentage; // 0-100
  final DateTime? lastDrinkTime;
  final DateTime? estimatedSoberTime;

  AlcoholBreakdown copyWith({
    double? alcoholRemaining,
    double? progressPercentage,
    DateTime? lastDrinkTime,
    DateTime? estimatedSoberTime,
  }) {
    return AlcoholBreakdown(
      alcoholRemaining: alcoholRemaining ?? this.alcoholRemaining,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lastDrinkTime: lastDrinkTime ?? this.lastDrinkTime,
      estimatedSoberTime: estimatedSoberTime ?? this.estimatedSoberTime,
    );
  }
}
