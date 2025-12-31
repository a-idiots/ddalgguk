import 'package:ddalgguk/core/widgets/settings_widgets.dart';
import 'package:ddalgguk/features/settings/services/drink_settings_service.dart';
import 'package:ddalgguk/features/settings/widgets/add_custom_drink_card.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainDrinkSettingsScreen extends ConsumerStatefulWidget {
  const MainDrinkSettingsScreen({super.key});

  @override
  ConsumerState<MainDrinkSettingsScreen> createState() =>
      _MainDrinkSettingsScreenState();
}

class _MainDrinkSettingsScreenState
    extends ConsumerState<MainDrinkSettingsScreen> {
  final Set<int> _selectedIds = {};
  List<Drink> _allDrinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(drinkSettingsServiceProvider);
      final savedIds = await service.loadMainDrinkIds();
      final customDrinks = await service.loadCustomDrinks();

      // Standard drinks excluding "Other" and "Undecided" which usually have negative or zero IDs not suitable for selection list if they are meta-types
      // Based on drink_helpers.dart: -1 is '기타', 0 is '알 수 없음'. We probably want to exclude them from "Main Drinks" selection.
      // Standard IDs are 1..9
      final standardDrinks = drinks.where((d) => d.id > 0).toList();

      setState(() {
        _allDrinks = [...standardDrinks, ...customDrinks];
        _selectedIds.clear();
        if (savedIds.isEmpty) {
          _selectedIds.addAll([1, 2, 4, 5, 3]);
        } else {
          _selectedIds.addAll(savedIds);
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading drink settings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleDrinkTap(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 5) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('최대 5개까지 선택할 수 있습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _handleSave() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메인 기록 주종을 최소 1개 이상 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    try {
      final service = ref.read(drinkSettingsServiceProvider);
      await service.saveMainDrinkIds(_selectedIds.toList());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  Future<void> _handleDeleteCustomDrink(Drink drink) async {
    final service = ref.read(drinkSettingsServiceProvider);
    await service.deleteCustomDrink(drink.id);

    setState(() {
      _allDrinks.removeWhere((d) => d.id == drink.id);
      _selectedIds.remove(drink.id);
    });
  }

  void _handleAddCustomDrink(Drink newDrink) async {
    // Check limit (Max 7 custom drinks)
    final customDrinkCount = _allDrinks.where((d) => d.id >= 1000).length;
    if (customDrinkCount >= 7) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('커스텀 주종은 최대 7개까지만 등록할 수 있습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Add to local storage
    final service = ref.read(drinkSettingsServiceProvider);
    await service.addCustomDrink(newDrink);

    // Update UI
    setState(() {
      _allDrinks.add(newDrink);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '메인 기록 주종',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '메인 기록 주종',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SettingsSectionDivider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 40.0,
              ),
              child: Column(
                children: [
                  const Text(
                    '*최대 5개까지 선택할 수 있습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75, // Adjust for icon + text
                        ),
                    itemCount: _allDrinks.length,
                    itemBuilder: (context, index) {
                      final drink = _allDrinks[index];
                      final isSelected = _selectedIds.contains(drink.id);

                      return GestureDetector(
                        onTap: () => _handleDrinkTap(drink.id),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF0A9A9)
                                            : Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          drink.imagePath,
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  drink.name,
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            if (drink.id >= 1000)
                              Positioned(
                                top: -8,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _handleDeleteCustomDrink(drink),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  // Always show AddCustomDrinkCard
                  AddCustomDrinkCard(onAdd: _handleAddCustomDrink),
                  const SizedBox(height: 40), // Spacing for fab/bottom button
                ],
              ),
            ),
          ),
          // Save Button Area
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
