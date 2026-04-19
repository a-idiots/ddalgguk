/// 랭킹 조회 결과 항목
class RankingEntry {
  RankingEntry({
    required this.uid,
    required this.amount,
    required this.addFriendPermission,
  });

  final String uid;

  /// 이번 주/달 누적 순수 알코올량 (ml)
  final double amount;

  /// 낯선 사람의 친구 요청 수락 여부
  final bool addFriendPermission;
}
