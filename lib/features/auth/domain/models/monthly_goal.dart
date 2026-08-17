/// 월별 음주 목표 (연도-월 키로 아카이빙)
class MonthlyGoal {
  const MonthlyGoal({this.budget, this.alcohol});

  factory MonthlyGoal.fromJson(Map<String, dynamic> json) {
    return MonthlyGoal(
      budget: (json['budget'] as num?)?.toInt(),
      alcohol: (json['alcohol'] as num?)?.toDouble(),
    );
  }

  final int? budget;
  final double? alcohol;

  bool get hasGoal => budget != null || alcohol != null;

  Map<String, dynamic> toJson() {
    return {
      if (budget != null) 'budget': budget,
      if (alcohol != null) 'alcohol': alcohol,
    };
  }
}
