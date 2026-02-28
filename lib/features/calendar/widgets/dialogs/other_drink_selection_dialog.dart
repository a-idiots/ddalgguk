import 'package:ddalgguk/features/settings/services/drink_settings_service.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtherDrinkSelectionDialog extends ConsumerStatefulWidget {
  const OtherDrinkSelectionDialog({
    super.key,
    this.excludeIds = const [],
  });

  /// 메인 기록 주종으로 이미 표시되는 ID — 이 목록에서 제외됨
  final List<int> excludeIds;

  @override
  ConsumerState<OtherDrinkSelectionDialog> createState() =>
      _OtherDrinkSelectionDialogState();
}

class _OtherDrinkSelectionDialogState
    extends ConsumerState<OtherDrinkSelectionDialog> {
  List<Drink> _allDrinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    try {
      // "기타" 아이콘(id=-1)을 맨 앞에 추가
      final gitaDrink = drinks.firstWhere((d) => d.id == -1);

      // 표준 주종(ID >= 1) 중 메인 목록에 이미 있는 것 제외
      final standardDrinks = drinks
          .where((d) => d.id >= 1 && !widget.excludeIds.contains(d.id))
          .toList();

      // 커스텀 주종도 메인 목록에 있는 것 제외
      final service = ref.read(drinkSettingsServiceProvider);
      final customDrinks = (await service.loadCustomDrinks())
          .where((d) => !widget.excludeIds.contains(d.id))
          .toList();

      if (mounted) {
        setState(() {
          _allDrinks = [gitaDrink, ...standardDrinks, ...customDrinks];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading drinks for dialog: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              height: 300,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: _allDrinks.length,
                      itemBuilder: (context, index) {
                        final drink = _allDrinks[index];
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
