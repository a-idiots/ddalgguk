import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

/// 술 종류 선택기 (하단 말풍선 형태)
class DrinkTypeSelector {
  static Future<void> show(
    BuildContext context, {
    required int currentType,
    required Function(int) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '술 종류 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // 좌우 스크롤 가능한 아이콘 리스트
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _DrinkTypeButton(
                    drinkType: 1,
                    label: '소주',
                    isSelected: currentType == 1,
                    onSelect: onSelect,
                  ),
                  const SizedBox(width: 16),
                  _DrinkTypeButton(
                    drinkType: 2,
                    label: '맥주',
                    isSelected: currentType == 2,
                    onSelect: onSelect,
                  ),
                  const SizedBox(width: 16),
                  _DrinkTypeButton(
                    drinkType: 3,
                    label: '와인',
                    isSelected: currentType == 3,
                    onSelect: onSelect,
                  ),
                  const SizedBox(width: 16),
                  _DrinkTypeButton(
                    drinkType: 4,
                    label: '막걸리',
                    isSelected: currentType == 4,
                    onSelect: onSelect,
                  ),
                  const SizedBox(width: 16),
                  _DrinkTypeButton(
                    drinkType: 5,
                    label: '칵테일',
                    isSelected: currentType == 5,
                    onSelect: onSelect,
                  ),
                  const SizedBox(width: 16),
                  _DrinkTypeButton(
                    drinkType: 6,
                    label: '기타',
                    isSelected: currentType == 6,
                    onSelect: onSelect,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// 술 종류 버튼
class _DrinkTypeButton extends StatelessWidget {
  const _DrinkTypeButton({
    required this.drinkType,
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  final int drinkType;
  final String label;
  final bool isSelected;
  final Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelect(drinkType);
        Navigator.pop(context); // 선택 후 말풍선 닫기
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Image.asset(
                getDrinkIconPath(drinkType),
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
