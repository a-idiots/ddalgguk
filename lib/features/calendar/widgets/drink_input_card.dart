import 'package:ddalgguk/features/calendar/models/drink_input_data.dart';
import 'package:ddalgguk/features/calendar/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

/// 음주량 입력 카드 빌더 (텍스트 입력 방식)
class DrinkInputCard extends StatelessWidget {
  const DrinkInputCard({
    required this.inputData,
    required this.onTypeChange,
    required this.onUnitChange,
    required this.onTypeTap,
    this.onDelete,
    super.key,
  });

  final DrinkInputData inputData;
  final Function(int) onTypeChange;
  final Function(String) onUnitChange;
  final VoidCallback onTypeTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 상단: 아이콘, 도수, 양
          Row(
            children: [
              // 술 종류 아이콘 (탭하면 선택 가능)
              GestureDetector(
                onTap: onTypeTap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: getDrinkIcon(inputData.drinkType)),
                ),
              ),
              const SizedBox(width: 8),
              // 도수 입력
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '도수',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: inputData.alcoholController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Text('%', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 양 입력 with 단위 선택
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '양',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: inputData.amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 2),
                      PopupMenuButton<String>(
                        initialValue: inputData.selectedUnit,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              inputData.selectedUnit,
                              style: const TextStyle(fontSize: 11),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                        onSelected: onUnitChange,
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: '병',
                                child: Text('병'),
                              ),
                              const PopupMenuItem<String>(
                                value: '잔',
                                child: Text('잔'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'ml',
                                child: Text('ml'),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 하단: 주종 이름과 삭제 버튼 (선택적)
          if (onDelete != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getDrinkTypeName(inputData.drinkType),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
