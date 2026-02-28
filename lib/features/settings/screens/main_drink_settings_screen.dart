import 'package:ddalgguk/core/providers/pro_provider.dart';
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
      final isPro = await ref.read(proProvider.future);
      final standardDrinks = drinks.where((d) => d.id > 0).toList();

      if (!isPro) {
        // 무료 유저: 기본 5개 고정, 커스텀 주종 없음
        setState(() {
          _allDrinks = standardDrinks;
          _selectedIds
            ..clear()
            ..addAll(kFreeDefaultDrinkIds);
          _isLoading = false;
        });
        return;
      }

      final service = ref.read(drinkSettingsServiceProvider);
      final savedIds = await service.loadMainDrinkIds();
      final customDrinks = await service.loadCustomDrinks();

      setState(() {
        _allDrinks = [...standardDrinks, ...customDrinks];
        _selectedIds.clear();
        if (savedIds.isEmpty) {
          _selectedIds.addAll(kFreeDefaultDrinkIds);
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

  bool get _isPro => ref.read(proProvider).valueOrNull ?? false;

  void _showProDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'DDALGGUK PRO',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '메인 기록 주종 커스터마이징은 PRO 기능이에요.\n구독 또는 1회 결제로 이용할 수 있어요.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '확인',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Color(0xFFF0A9A9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDrinkTap(int id) {
    if (!_isPro) {
      _showProDialog();
      return;
    }
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
    if (!_isPro) {
      _showProDialog();
      return;
    }
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
    if (!_isPro) {
      _showProDialog();
      return;
    }
    final service = ref.read(drinkSettingsServiceProvider);
    await service.deleteCustomDrink(drink.id);

    setState(() {
      _allDrinks.removeWhere((d) => d.id == drink.id);
      _selectedIds.remove(drink.id);
    });
  }

  void _showAddCustomDrinkDialog() {
    if (!_isPro) {
      _showProDialog();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          height: 250,
          child: AddCustomDrinkCard(
            onAdd: (newDrink) {
              _handleAddCustomDrink(newDrink);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
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
              fontFamily: 'Pretendard',
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
            fontFamily: 'Pretendard',
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
                    itemCount:
                        _allDrinks.length +
                        (_allDrinks.where((d) => d.id >= 1000).length < 7
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index == _allDrinks.length) {
                        return GestureDetector(
                          onTap: _showAddCustomDrinkDialog,
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.add, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '직접 추가',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }

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
