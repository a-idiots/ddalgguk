import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/features/calendar/domain/models/drink_input_data.dart';
import 'package:ddalgguk/features/calendar/widgets/dialogs/other_drink_selection_dialog.dart';
import 'package:ddalgguk/features/settings/services/drink_settings_service.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// 새로운 음주량 입력 카드
class NewDrinkInputCard extends ConsumerStatefulWidget {
  const NewDrinkInputCard({
    required this.inputData,
    required this.onAdd,
    super.key,
  });

  final DrinkInputData inputData;
  final VoidCallback onAdd;

  @override
  ConsumerState<NewDrinkInputCard> createState() => _NewDrinkInputCardState();
}

class _NewDrinkInputCardState extends ConsumerState<NewDrinkInputCard> {
  List<int> _mainDrinkIds = [
    1,
    2,
    4,
    5,
    3,
  ]; // Default order: Soju, Beer, Wine, Makgeolli, Cocktail

  @override
  void initState() {
    super.initState();
    _loadMainDrinkSettings();
  }

  static const List<int> _freeDefaultDrinkIds = kFreeDefaultDrinkIds;

  Future<void> _loadMainDrinkSettings() async {
    try {
      final isPro = await ref.read(proProvider.future);

      if (!isPro) {
        // 무료 전환 시 storage도 기본값으로 리셋
        final service = ref.read(drinkSettingsServiceProvider);
        await service.saveMainDrinkIds(List.of(_freeDefaultDrinkIds));
        if (mounted) {
          setState(() {
            _mainDrinkIds = _freeDefaultDrinkIds;
            _customDrinks = [];
          });
        }
        return;
      }

      final service = ref.read(drinkSettingsServiceProvider);
      final savedIds = await service.loadMainDrinkIds();
      final customDrinks = await service.loadCustomDrinks();

      if (mounted) {
        setState(() {
          _mainDrinkIds = savedIds.isNotEmpty
              ? savedIds.take(5).toList()
              : _mainDrinkIds;
          _customDrinks = customDrinks;
        });
      }
    } catch (e) {
      debugPrint('Failed to load main drink settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pro 상태가 바뀌면 주종 목록 재로드 (Pro→free 시 리셋, free→Pro 시 저장된 설정 복원)
    ref.listen<AsyncValue<bool>>(proProvider, (previous, next) {
      final wasPro = previous?.valueOrNull ?? false;
      final isPro = next.valueOrNull ?? false;
      if (wasPro != isPro) {
        _loadMainDrinkSettings();
      }
    });

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
          // 주류 아이콘 6개 (Up to 5 Main Drinks + 1 Other)
          // If less than 5 main drinks, we just show them.
          // But UI design usually has fixed grid or row. The design shows 2 rows of 3 icons (total 6 spots)? Or 1 row scrollable?
          // The current code has a Row with spaceEvenly for 6 items.
          // Let's keep 6 slots. 5 Main + 1 Other.
          // Custom layout for left alignment
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ..._mainDrinkIds.map((id) => _buildDrinkTypeButton(id)),
                  _buildDrinkTypeButton(-1),
                  ...List.generate(
                    5 - _mainDrinkIds.length,
                    (index) => const SizedBox(width: 44),
                  ),
                ],
              );
            },
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
              suffixIcon: _buildUnitSelector(),
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

          // Pro 홍보 문구 (Pro가 아닐 때만 표시)
          if (!(ref.watch(proProvider).valueOrNull ?? false)) ...[
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                children: [
                  const TextSpan(text: '기본 주종 외의 주종 아이콘은 '),
                  const TextSpan(
                    text: '딸꾹 Pro',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: '를 구독해서 이용해보세요!  '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: navigate to Pro purchase screen
                      },
                      child: const Text(
                        '더 알아보기',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 11,
                          color: Color(0xFFF0A9A9),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFF0A9A9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  List<Drink> _customDrinks = [];

  /// 선택된 주종에서 사용 가능한 단위 목록을 반환.
  /// 커스텀 주종(id >= 1000)은 ml만, 그 외는 볼륨 값에 따라 필터링.
  List<String> _getAvailableUnits(int drinkType) {
    if (drinkType >= 1000) {
      return ['ml'];
    }

    Drink? d = drinks.where((d) => d.id == drinkType).firstOrNull;
    d ??= _customDrinks.where((d) => d.id == drinkType).firstOrNull;
    if (d == null) {
      return ['ml', '잔', '병'];
    }

    return ['ml', if (d.glassVolume > 0) '잔', if (d.bottleVolume > 0) '병'];
  }

  Widget _buildUnitSelector() {
    final availableUnits = _getAvailableUnits(widget.inputData.drinkType);

    // 단위가 ml 하나뿐이면 드롭다운 없이 정적 텍스트
    if (availableUnits.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Text('ml', style: TextStyle(fontSize: 16)),
      );
    }

    return Container(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        initialValue: widget.inputData.selectedUnit,
        color: Colors.grey[200],
        onSelected: (String newUnit) {
          setState(() {
            widget.inputData.selectedUnit = newUnit;
          });
        },
        itemBuilder: (BuildContext context) => availableUnits
            .map(
              (unit) => PopupMenuItem<String>(value: unit, child: Text(unit)),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.inputData.selectedUnit,
                style: const TextStyle(fontSize: 16),
              ),
              Icon(Icons.arrow_drop_down, size: 28, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkTypeButton(int type) {
    final bool isOtherButton = type == -1;
    // '기타' 버튼이 선택된 상태인지
    final bool isCustomDrinkSelected =
        widget.inputData.drinkType > 5 &&
        !_mainDrinkIds.contains(widget.inputData.drinkType);

    // 이 버튼이 선택되었는지 판별
    bool isSelected;
    if (isOtherButton) {
      isSelected = isCustomDrinkSelected || widget.inputData.drinkType == -1;
    } else {
      isSelected = widget.inputData.drinkType == type;
    }

    // 표시할 라벨과 아이콘
    String label;
    Widget icon;

    // Helper to find drink by ID from standard + custom
    Drink? findDrink(int id) {
      Drink? d = drinks.where((d) => d.id == id).firstOrNull;
      if (d == null && _customDrinks.isNotEmpty) {
        d = _customDrinks.where((d) => d.id == id).firstOrNull;
      }
      return d;
    }

    if (isOtherButton && isCustomDrinkSelected) {
      // 기타 버튼인데 메인 리스트에 없는 커스텀/기타 술이 선택된 경우
      final drink = findDrink(widget.inputData.drinkType);
      label = drink?.name ?? getDrinkTypeName(widget.inputData.drinkType);
      icon = drink != null
          ? Image.asset(
              drink.imagePath,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            )
          : getDrinkIcon(widget.inputData.drinkType);
    } else {
      // 일반 버튼 (메인 리스트에 있는 버튼)
      final drink = findDrink(type);
      if (drink != null) {
        label = drink.name;
        icon = Image.asset(
          drink.imagePath,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
      } else {
        label = getDrinkTypeName(type);
        icon = getDrinkIcon(type);
      }
    }

    return GestureDetector(
      onTap: () async {
        if (isOtherButton) {
          final isPro = ref.read(proProvider).valueOrNull ?? false;
          if (isPro) {
            if (!context.mounted) {
              return;
            }
            final selectedId = await showDialog<int>(
              context: context,
              builder: (context) =>
                  OtherDrinkSelectionDialog(excludeIds: _mainDrinkIds),
            );
            if (selectedId != null) {
              setState(() {
                _updateDrinkData(selectedId);
              });
            }
          } else {
            setState(() {
              _updateDrinkData(-1);
            });
          }
        } else {
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

    // Find drink to get default alcohol content
    double defaultAlcohol = 0.0;
    String defaultUnit = 'ml';

    Drink? d = drinks.where((d) => d.id == type).firstOrNull;
    if (d == null && _customDrinks.isNotEmpty) {
      d = _customDrinks.where((d) => d.id == type).firstOrNull;
    }

    if (d != null) {
      defaultAlcohol = d.defaultAlcoholContent;
      defaultUnit = d.defaultUnit;
    } else {
      defaultAlcohol = getDefaultAlcoholContent(type);
      defaultUnit = getDefaultUnit(type);
    }

    widget.inputData.alcoholController.text = defaultAlcohol.toString();

    // defaultUnit이 이 주종에서 허용되지 않는 경우 ml로 폴백
    final availableUnits = _getAvailableUnits(type);
    widget.inputData.selectedUnit = availableUnits.contains(defaultUnit)
        ? defaultUnit
        : availableUnits.first;
  }
}
