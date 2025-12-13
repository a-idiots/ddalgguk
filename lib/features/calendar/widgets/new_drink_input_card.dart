import 'package:ddalgguk/features/calendar/domain/models/drink_input_data.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
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
              _buildDrinkTypeButton(context, 1, '소주'),
              _buildDrinkTypeButton(context, 2, '맥주'),
              _buildDrinkTypeButton(context, 4, '와인'),
              _buildDrinkTypeButton(context, 5, '막걸리'),
              _buildDrinkTypeButton(context, 3, '칵테일'),
              _buildDrinkTypeButton(context, 6, '기타'),
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
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.inputData.selectedUnit,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
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

  Widget _buildDrinkTypeButton(BuildContext context, int type, String label) {
    final isSelected = widget.inputData.drinkType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.inputData.drinkType = type;
          widget.inputData.alcoholController.text = getDefaultAlcoholContent(type).toString();
          widget.inputData.selectedUnit = getDefaultUnit(type);
        });
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? Colors.pink.withValues(alpha: 0.3) : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: getDrinkIcon(type),
            ),
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
}
