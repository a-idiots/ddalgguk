class WeeklyStats {
  const WeeklyStats({
    required this.startDate,
    required this.endDate,
    required this.dailyData,
    required this.totalSessions,
    required this.totalAlcoholMl,
    required this.totalCost,
    required this.averageDrunkLevel,
    required this.soberDays,
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
        ),
      ),
      totalSessions: 0,
      totalAlcoholMl: 0,
      totalCost: 0,
      averageDrunkLevel: 0,
      soberDays: 7,
    );
  }

  final DateTime startDate;
  final DateTime endDate;
  final List<DailySakuData> dailyData; // 7 days of data
  final int totalSessions;
  final double totalAlcoholMl;
  final int totalCost;
  final double averageDrunkLevel;
  final int soberDays;

  WeeklyStats copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<DailySakuData>? dailyData,
    int? totalSessions,
    double? totalAlcoholMl,
    int? totalCost,
    double? averageDrunkLevel,
    int? soberDays,
  }) {
    return WeeklyStats(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyData: dailyData ?? this.dailyData,
      totalSessions: totalSessions ?? this.totalSessions,
      totalAlcoholMl: totalAlcoholMl ?? this.totalAlcoholMl,
      totalCost: totalCost ?? this.totalCost,
      averageDrunkLevel: averageDrunkLevel ?? this.averageDrunkLevel,
      soberDays: soberDays ?? this.soberDays,
    );
  }
}

class DailySakuData {
  const DailySakuData({
    required this.date,
    required this.drunkLevel,
    required this.hasRecords,
  });

  final DateTime date;
  final int drunkLevel; // 0-100
  final bool hasRecords;

  DailySakuData copyWith({DateTime? date, int? drunkLevel, bool? hasRecords}) {
    return DailySakuData(
      date: date ?? this.date,
      drunkLevel: drunkLevel ?? this.drunkLevel,
      hasRecords: hasRecords ?? this.hasRecords,
    );
  }
}
