import 'package:ddalgguk/features/calendar/domain/models/drink_input_data.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/features/calendar/widgets/dialogs/other_drink_selection_dialog.dart';
import 'package:flutter/material.dart';

/// 새로운 음주량 입력 카드
class NewDrinkInputCard extends StatefulWidget {
  const NewDrinkInputCard({
    required this.inputData,
    required this.onAdd,
    super.key,
  });

  final DrinkInputData inputData;
  final VoidCallback onAdd;

  @override
  State<NewDrinkInputCard> createState() => _NewDrinkInputCardState();
}

class _NewDrinkInputCardState extends State<NewDrinkInputCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 주류 아이콘 6개
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDrinkTypeButton(1),
              _buildDrinkTypeButton(2),
              _buildDrinkTypeButton(4),
              _buildDrinkTypeButton(5),
              _buildDrinkTypeButton(3),
              _buildDrinkTypeButton(-1),
            ],
          ),
          const SizedBox(height: 16),

          // 도수 입력창
          TextField(
            controller: widget.inputData.alcoholController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '도수를 입력해주세요.',
              hintStyle: TextStyle(color: Colors.grey[400]),
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 양 입력창
          TextField(
            controller: widget.inputData.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '양을 입력해주세요.',
              hintStyle: TextStyle(color: Colors.grey[400]),
              suffixIcon: Container(
                padding: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<String>(
                  initialValue: widget.inputData.selectedUnit,
                  color: Colors.grey[200],
                  onSelected: (String newUnit) {
                    setState(() {
                      widget.inputData.selectedUnit = newUnit;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'ml',
                          child: Text('ml'),
                        ),
                        const PopupMenuItem<String>(
                          value: '잔',
                          child: Text('잔'),
                        ),
                        const PopupMenuItem<String>(
                          value: '병',
                          child: Text('병'),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.inputData.selectedUnit,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 28,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 추가 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onAdd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('추가', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkTypeButton(int type) {
    final bool isOtherButton = type == -1;
    // '기타' 버튼이 선택된 상태인지: 현재 선택된 drinkType이 주어졌던 type(-1)이 아니라,
    // [1, 2, 3, 4, 5] 범위를 벗어난 경우 (즉 6, 7, 8...)도 '기타' 영역이 활성화된 것으로 간주
    // 단, 여기서 type 인자는 버튼의 고유 ID이므로:
    // 1. 일반 버튼(1~5)은 자신의 번호와 현재 drinkType이 같으면 선택됨.
    // 2. 기타 버튼(-1)은 현재 drinkType이 1,2,3,4,5가 아닌 다른 양수(6,7,8...)일 때 선택된 것으로 표시 + 아이콘 변경.

    // 표준 버튼 목록에 없는 ID인지 확인 (6 이상)
    final bool isCustomDrinkSelected = widget.inputData.drinkType > 5;

    // 이 버튼이 선택되었는지 판별
    bool isSelected;
    if (isOtherButton) {
      // 기타 버튼은 현재 선택된 술이 1~5가 아니고 0(미선택)도 아닐 때 선택 상태
      isSelected = isCustomDrinkSelected;
    } else {
      isSelected = widget.inputData.drinkType == type;
    }

    // 표시할 라벨과 아이콘
    String label;
    Widget icon;

    if (isOtherButton && isCustomDrinkSelected) {
      // 기타 버튼인데 커스텀 술이 선택된 경우 -> 해당 술의 정보 표시
      label = getDrinkTypeName(widget.inputData.drinkType);
      icon = getDrinkIcon(widget.inputData.drinkType);
    } else {
      // 그 외 (일반 버튼 or 기타 버튼 미선택/기본 상태)
      label = getDrinkTypeName(type);
      icon = getDrinkIcon(type);
    }

    return GestureDetector(
      onTap: () async {
        if (isOtherButton) {
          // 기타 버튼 클릭 시 다이얼로그 표시
          final selectedId = await showDialog<int>(
            context: context,
            builder: (context) => const OtherDrinkSelectionDialog(),
          );

          if (selectedId != null) {
            setState(() {
              _updateDrinkData(selectedId);
            });
          }
        } else {
          // 일반 버튼 클릭
          setState(() {
            _updateDrinkData(type);
          });
        }
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.pink.withValues(alpha: 0.3)
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.black87 : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _updateDrinkData(int type) {
    widget.inputData.drinkType = type;
    widget.inputData.alcoholController.text = getDefaultAlcoholContent(
      type,
    ).toString();
    widget.inputData.selectedUnit = getDefaultUnit(type);
  }
}
