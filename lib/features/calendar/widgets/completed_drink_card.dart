import 'package:ddalgguk/features/calendar/domain/models/completed_drink_record.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

/// 완료된 음주 기록 카드 (편집 불가, 삭제만 가능)
class CompletedDrinkCard extends StatelessWidget {
  const CompletedDrinkCard({
    required this.record,
    required this.onDelete,
    super.key,
  });

  final CompletedDrinkRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(child: getDrinkIcon(record.drinkType)),
          ),
          const SizedBox(width: 12),

          // 정보 텍스트
          Expanded(
            child: Text(
              '${getDrinkTypeName(record.drinkType)} · ${record.alcoholContent}% · ${record.amount}${record.unit}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),

          // 삭제 버튼
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 24),
            color: Colors.grey[600],
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
