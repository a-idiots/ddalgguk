class ProfileStats {
  const ProfileStats({
    required this.thisMonthDrunkDays,
    required this.currentAlcoholInBody,
    required this.timeToSober,
    required this.statusMessage,
    required this.breakdown,
    this.thisMonthDrinkingCount = 0,
    this.thisMonthSoberCount = 0,
    this.todayDrunkLevel = 0,
    this.hasTodayRecord = false,
    this.isTodayDrinking = false,
  });

  factory ProfileStats.empty() {
    return ProfileStats(
      thisMonthDrunkDays: 0,
      currentAlcoholInBody: 0,
      timeToSober: 0,
      statusMessage: '건강한 상태입니다',
      breakdown: AlcoholBreakdown.empty(),
      thisMonthDrinkingCount: 0,
      thisMonthSoberCount: 0,
      todayDrunkLevel: 0,
      hasTodayRecord: false,
      isTodayDrinking: false,
    );
  }

  final int thisMonthDrunkDays; // 0-100
  final double currentAlcoholInBody; // in grams
  final double timeToSober; // in hours
  final String statusMessage;
  final AlcoholBreakdown breakdown;
  final int thisMonthDrinkingCount;
  final int thisMonthSoberCount;
  final int todayDrunkLevel;
  final bool hasTodayRecord;
  final bool isTodayDrinking;

  ProfileStats copyWith({
    int? currentDrunkLevel,
    double? currentAlcoholInBody,
    double? timeToSober,
    String? statusMessage,
    AlcoholBreakdown? breakdown,
    int? thisMonthDrinkingCount,
    int? thisMonthSoberCount,
    int? todayDrunkLevel,
    bool? hasTodayRecord,
    bool? isTodayDrinking,
  }) {
    return ProfileStats(
      thisMonthDrunkDays: currentDrunkLevel ?? thisMonthDrunkDays,
      currentAlcoholInBody: currentAlcoholInBody ?? this.currentAlcoholInBody,
      timeToSober: timeToSober ?? this.timeToSober,
      statusMessage: statusMessage ?? this.statusMessage,
      breakdown: breakdown ?? this.breakdown,
      thisMonthDrinkingCount:
          thisMonthDrinkingCount ?? this.thisMonthDrinkingCount,
      thisMonthSoberCount: thisMonthSoberCount ?? this.thisMonthSoberCount,
      todayDrunkLevel: todayDrunkLevel ?? this.todayDrunkLevel,
      hasTodayRecord: hasTodayRecord ?? this.hasTodayRecord,
      isTodayDrinking: isTodayDrinking ?? this.isTodayDrinking,
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
