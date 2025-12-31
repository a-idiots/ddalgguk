import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';

class OtherDrinkSelectionDialog extends StatelessWidget {
  const OtherDrinkSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // ID가 1 이상인 모든 술을 가져옵니다.
    final availableDrinks = drinks.where((d) => d.id >= 1).toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // 공간 맞추기용
                const Text(
                  '기타 주종 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300, // 적절한 높이 제한
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: availableDrinks.length,
                itemBuilder: (context, index) {
                  final drink = availableDrinks[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, drink.id),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            drink.imagePath,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/imgs/alcohol_icons/undecided.png',
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          drink.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
