import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// 음주량 정보를 담는 클래스
/// [drinkType] - 술 종류 (int)
/// [alcoholContent] - 도수 (float)
/// [amount] - 양 (float)
class DrinkAmount {
  DrinkAmount({
    required this.drinkType,
    required this.alcoholContent,
    required this.amount,
  });

  factory DrinkAmount.fromMap(Map<String, dynamic> map) {
    return DrinkAmount(
      drinkType: map['drinkType'] as int,
      alcoholContent: (map['alcoholContent'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
    );
  }
  final int drinkType;
  final double alcoholContent;
  final double amount;

  Map<String, dynamic> toMap() {
    return {
      'drinkType': drinkType,
      'alcoholContent': alcoholContent,
      'amount': amount,
    };
  }
}

/// 음주 기록 모델 클래스
class DrinkingRecord {
  // 술값

  DrinkingRecord({
    required this.id,
    required this.date,
    required this.yearMonth,
    required this.sessionNumber,
    required this.meetingName,
    required this.drunkLevel,
    required this.drinkAmount,
    required this.memo,
    required this.cost,
  });

  /// Firestore 문서로부터 DrinkingRecord 생성
  factory DrinkingRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return DrinkingRecord(
      id: snapshot.id,
      date: DateTime.parse(data['date'] as String),
      yearMonth: data['yearMonth'] as String,
      sessionNumber: data['sessionNumber'] as int,
      meetingName: data['meetingName'] as String,
      drunkLevel: data['drunkLevel'] as int,
      drinkAmount: (data['drinkAmount'] as List<dynamic>)
          .map((drink) => DrinkAmount.fromMap(drink as Map<String, dynamic>))
          .toList(),
      memo: Map<String, dynamic>.from(data['memo'] as Map),
      cost: data['cost'] as int,
    );
  }
  final String id; // Firestore document ID
  final DateTime date; // 날짜 (DB: String YYYY-MM-DD)
  final String yearMonth; // YYYY-MM
  final int sessionNumber; // 기록 회차 (날짜별로)
  final String meetingName; // 모임명
  final int drunkLevel; // 취함 정도
  final List<DrinkAmount> drinkAmount; // 음주량 리스트
  final Map<String, dynamic> memo; // 메모
  final int cost;

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'yearMonth': yearMonth,
      'sessionNumber': sessionNumber,
      'meetingName': meetingName,
      'drunkLevel': drunkLevel,
      'drinkAmount': drinkAmount.map((drink) => drink.toMap()).toList(),
      'memo': memo,
      'cost': cost,
    };
  }

  /// copyWith 메서드 - 일부 필드만 업데이트할 때 사용
  DrinkingRecord copyWith({
    String? id,
    DateTime? date,
    String? yearMonth,
    int? sessionNumber,
    String? meetingName,
    int? drunkLevel,
    List<DrinkAmount>? drinkAmount,
    Map<String, dynamic>? memo,
    int? cost,
  }) {
    return DrinkingRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      yearMonth: yearMonth ?? this.yearMonth,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      meetingName: meetingName ?? this.meetingName,
      drunkLevel: drunkLevel ?? this.drunkLevel,
      drinkAmount: drinkAmount ?? this.drinkAmount,
      memo: memo ?? this.memo,
      cost: cost ?? this.cost,
    );
  }
}
