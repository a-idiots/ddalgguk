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
  bool _showAddCard = false;

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
        _selectedIds.addAll(savedIds);
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

  void _handleAddCustomDrink(Drink newDrink) async {
    // Add to local storage
    final service = ref.read(drinkSettingsServiceProvider);
    await service.addCustomDrink(newDrink);

    // Update UI
    setState(() {
      _allDrinks.add(newDrink);
      _showAddCard = false;
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
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFFF0A9A9,
                                          ) // Selected color (light red/pink)
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
                                // We could add a checkmark overlay if needed, but background color change is usually enough
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
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (!_showAddCard)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddCard = true),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('추가 등록'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  if (_showAddCard)
                    AddCustomDrinkCard(
                      onCancel: () => setState(() => _showAddCard = false),
                      onAdd: _handleAddCustomDrink,
                    ),
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
