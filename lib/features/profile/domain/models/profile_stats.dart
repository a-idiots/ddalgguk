class ProfileStats {
  final int thisMonthDrunkDays; // 0-100
  final double currentAlcoholInBody; // in grams
  final double timeToSober; // in hours
  final String statusMessage;
  final AlcoholBreakdown breakdown;

  const ProfileStats({
    required this.thisMonthDrunkDays,
    required this.currentAlcoholInBody,
    required this.timeToSober,
    required this.statusMessage,
    required this.breakdown,
  });

  factory ProfileStats.empty() {
    return ProfileStats(
      thisMonthDrunkDays: 0,
      currentAlcoholInBody: 0,
      timeToSober: 0,
      statusMessage: '건강한 상태입니다',
      breakdown: AlcoholBreakdown.empty(),
    );
  }

  ProfileStats copyWith({
    int? currentDrunkLevel,
    double? currentAlcoholInBody,
    double? timeToSober,
    String? statusMessage,
    AlcoholBreakdown? breakdown,
  }) {
    return ProfileStats(
      thisMonthDrunkDays: currentDrunkLevel ?? this.thisMonthDrunkDays,
      currentAlcoholInBody: currentAlcoholInBody ?? this.currentAlcoholInBody,
      timeToSober: timeToSober ?? this.timeToSober,
      statusMessage: statusMessage ?? this.statusMessage,
      breakdown: breakdown ?? this.breakdown,
    );
  }
}

class AlcoholBreakdown {
  final double totalAlcoholConsumed; // in grams
  final double alcoholRemaining; // in grams
  final double alcoholProcessed; // in grams
  final double progressPercentage; // 0-100
  final DateTime? lastDrinkTime;
  final DateTime? estimatedSoberTime;

  const AlcoholBreakdown({
    required this.totalAlcoholConsumed,
    required this.alcoholRemaining,
    required this.alcoholProcessed,
    required this.progressPercentage,
    this.lastDrinkTime,
    this.estimatedSoberTime,
  });

  factory AlcoholBreakdown.empty() {
    return const AlcoholBreakdown(
      totalAlcoholConsumed: 0,
      alcoholRemaining: 0,
      alcoholProcessed: 0,
      progressPercentage: 0,
    );
  }

  AlcoholBreakdown copyWith({
    double? totalAlcoholConsumed,
    double? alcoholRemaining,
    double? alcoholProcessed,
    double? progressPercentage,
    DateTime? lastDrinkTime,
    DateTime? estimatedSoberTime,
  }) {
    return AlcoholBreakdown(
      totalAlcoholConsumed: totalAlcoholConsumed ?? this.totalAlcoholConsumed,
      alcoholRemaining: alcoholRemaining ?? this.alcoholRemaining,
      alcoholProcessed: alcoholProcessed ?? this.alcoholProcessed,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lastDrinkTime: lastDrinkTime ?? this.lastDrinkTime,
      estimatedSoberTime: estimatedSoberTime ?? this.estimatedSoberTime,
    );
  }
}
