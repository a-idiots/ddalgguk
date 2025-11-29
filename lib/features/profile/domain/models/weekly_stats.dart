class WeeklyStats {
  const WeeklyStats({
    required this.startDate,
    required this.endDate,
    required this.dailyData,
    required this.soberDays,
    required this.drinkTypeStats,
  });

  factory WeeklyStats.empty(DateTime startDate) {
    return WeeklyStats(
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 6)),
      dailyData: List.generate(
        7,
        (index) => DailySakuData(
          date: startDate.add(Duration(days: index)),
          drunkLevel: 0,
          hasRecords: false,
          totalAlcoholMl: 0,
        ),
      ),
      soberDays: 7,
      drinkTypeStats: [],
    );
  }

  final DateTime startDate;
  final DateTime endDate;
  final List<DailySakuData> dailyData; // 7 days of data
  final int soberDays;
  final List<DrinkTypeStat> drinkTypeStats;

  double get totalAlcoholMl =>
      drinkTypeStats.fold(0, (sum, stat) => sum + stat.totalAmountMl);

  double get totalPureAlcoholMl =>
      drinkTypeStats.fold(0, (sum, stat) => sum + stat.pureAlcoholMl);

  int get totalSessions => dailyData.where((d) => d.hasRecords).length;

  double get averageDrunkLevel {
    final drunkDays = dailyData.where((d) => d.hasRecords);
    if (drunkDays.isEmpty) {
      return 0.0;
    }
    final sum = drunkDays.fold(0, (sum, d) => sum + d.drunkLevel);
    return sum / drunkDays.length;
  }

  WeeklyStats copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<DailySakuData>? dailyData,
    int? soberDays,
    List<DrinkTypeStat>? drinkTypeStats,
  }) {
    return WeeklyStats(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyData: dailyData ?? this.dailyData,
      soberDays: soberDays ?? this.soberDays,
      drinkTypeStats: drinkTypeStats ?? this.drinkTypeStats,
    );
  }
}

class DrinkTypeStat {
  const DrinkTypeStat({
    required this.drinkType,
    required this.totalAmountMl,
    required this.maxAmountMl,
    this.pureAlcoholMl = 0.0,
  });

  final int drinkType; // 0=Soju, 1=Beer, 2=Wine, 3=Etc
  final double totalAmountMl;
  final double maxAmountMl;
  final double pureAlcoholMl;

  DrinkTypeStat copyWith({
    int? drinkType,
    double? totalAmountMl,
    double? maxAmountMl,
    double? pureAlcoholMl,
  }) {
    return DrinkTypeStat(
      drinkType: drinkType ?? this.drinkType,
      totalAmountMl: totalAmountMl ?? this.totalAmountMl,
      maxAmountMl: maxAmountMl ?? this.maxAmountMl,
      pureAlcoholMl: pureAlcoholMl ?? this.pureAlcoholMl,
    );
  }
}

class DailySakuData {
  const DailySakuData({
    required this.date,
    required this.drunkLevel,
    required this.hasRecords,
    this.totalAlcoholMl = 0.0,
  });

  final DateTime date;
  final int drunkLevel; // 0-100
  final bool hasRecords;
  final double totalAlcoholMl;

  DailySakuData copyWith({
    DateTime? date,
    int? drunkLevel,
    bool? hasRecords,
    double? totalAlcoholMl,
  }) {
    return DailySakuData(
      date: date ?? this.date,
      drunkLevel: drunkLevel ?? this.drunkLevel,
      hasRecords: hasRecords ?? this.hasRecords,
      totalAlcoholMl: totalAlcoholMl ?? this.totalAlcoholMl,
    );
  }
}
