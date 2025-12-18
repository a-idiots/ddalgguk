/// 완료된 음주 기록 (편집 불가)
class CompletedDrinkRecord {
  CompletedDrinkRecord({
    required this.drinkType,
    required this.alcoholContent,
    required this.amount,
    required this.unit,
  });

  final int drinkType;
  final double alcoholContent;
  final double amount;
  final String unit;
}
