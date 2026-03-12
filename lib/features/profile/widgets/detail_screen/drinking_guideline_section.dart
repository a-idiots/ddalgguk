import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/providers/pro_provider.dart';
import 'package:ddalgguk/features/profile/data/providers/profile_providers.dart';
import 'package:ddalgguk/shared/utils/drink_helpers.dart';
import 'package:ddalgguk/shared/widgets/pro_plan_popup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level section widget
// ─────────────────────────────────────────────────────────────────────────────

class DrinkingGuidelineSection extends ConsumerWidget {
  const DrinkingGuidelineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidelineAsync = ref.watch(alcoholGuidelineDataProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isPro = ref.watch(proProvider).valueOrNull ?? false;

    final nickname = userAsync.valueOrNull?.name ?? '';
    final gender = userAsync.valueOrNull?.gender ?? 'male';

    return guidelineAsync.when(
      skipLoadingOnReload: true,
      data: (data) => _GuidelineCard(
        nickname: nickname,
        gender: gender,
        data: data,
        isPro: isPro,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────────────────────

class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard({
    required this.nickname,
    required this.gender,
    required this.data,
    required this.isPro,
  });

  final String nickname;
  final String gender;
  final AlcoholGuidelineData data;
  final bool isPro;

  (String, Color) _classify(double grams) {
    final isFemale = gender == 'female';
    if (isFemale) {
      if (grams <= 20) {
        return ('적절하게 음주', const Color(0xFF4CAF50));
      }
      if (grams <= 40) {
        return ('조금 위험하게 음주', const Color(0xFFFFC107));
      }
      if (grams <= 60) {
        return ('꽤나 위험하게 음주', const Color(0xFFFF9800));
      }
      return ('매우 위험하게 음주', const Color(0xFFF44336));
    } else {
      if (grams <= 40) {
        return ('적절하게 음주', const Color(0xFF4CAF50));
      }
      if (grams <= 60) {
        return ('조금 위험하게 음주', const Color(0xFFFFC107));
      }
      if (grams <= 100) {
        return ('꽤나 위험하게 음주', const Color(0xFFFF9800));
      }
      return ('매우 위험하게 음주', const Color(0xFFF44336));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: data.hasRecord
          ? _RecordContent(
              nickname: nickname,
              data: data,
              classify: _classify,
              isPro: isPro,
            )
          : _EmptyContent(nickname: nickname),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card content – record exists
// ─────────────────────────────────────────────────────────────────────────────

class _RecordContent extends StatelessWidget {
  const _RecordContent({
    required this.nickname,
    required this.data,
    required this.classify,
    required this.isPro,
  });

  final String nickname;
  final AlcoholGuidelineData data;
  final (String, Color) Function(double) classify;
  final bool isPro;

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _GuidelineDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (message, color) = classify(data.totalAlcoholGrams);
    final whenLabel = data.isToday ? '오늘' : '어제';

    return Column(
      children: [
        if (isPro)
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              children: [
                TextSpan(text: '$nickname님은 $whenLabel\n'),
                TextSpan(
                  text: message,
                  style: TextStyle(color: color),
                ),
                const TextSpan(text: '했어요!'),
              ],
            ),
            textAlign: TextAlign.center,
          )
        else
          const Text(
            '프로 플랜으로 업그레이드해서\n음주 가이드라인을 확인해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        const SizedBox(height: 16),
        // Day pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            whenLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPro ? '총 ${data.totalAlcoholGrams.toStringAsFixed(1)}g' : '??.? g',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: isPro
              ? () => _showDialog(context)
              : () => showProPlanPopup(context, 2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '자세히보기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card content – no record
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$nickname님, 캘린더에서 음주 또는 금주 기록을 추가해보세요!',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _GuidelineDialog extends StatefulWidget {
  const _GuidelineDialog({required this.data});
  final AlcoholGuidelineData data;

  @override
  State<_GuidelineDialog> createState() => _GuidelineDialogState();
}

class _GuidelineDialogState extends State<_GuidelineDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = widget.data.isToday ? '오늘' : '어제';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // X button row
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Title – full width, properly centered
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              '음주 가이드라인',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Day pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dayLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _InfoBox(data: widget.data),
          ),
          const SizedBox(height: 16),
          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.black,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2, color: Colors.black),
              borderRadius: BorderRadius.zero,
            ),
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            tabs: const [
              Tab(height: 30, text: '음주 위험도 분류 기준'),
              Tab(height: 30, text: '순수 알코올 양 계산'),
            ],
          ),
          // Tab content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: const [_GuidelineTab(), _CalculationTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info box (drink breakdown + total)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.data});
  final AlcoholGuidelineData data;

  String _formatLine(DrinkBreakdownItem item) {
    final drink = drinks.where((d) => d.id == item.drinkType).firstOrNull;
    final glassVol = drink?.glassVolume ?? 0;
    final mlStr = item.totalAmountMl.toStringAsFixed(0);

    if (glassVol > 0) {
      final glasses = item.totalAmountMl / glassVol;
      final rounded = (glasses * 2).round() / 2;
      if ((glasses - rounded).abs() < 0.06 && rounded > 0) {
        final glassStr = rounded == rounded.truncateToDouble()
            ? rounded.toInt().toString()
            : rounded.toStringAsFixed(1);
        return '${item.name} $glassStr잔 = ${mlStr}ml = 약 ${item.grams.toStringAsFixed(1)}g';
      }
    }
    return '${item.name} ${mlStr}ml = 약 ${item.grams.toStringAsFixed(1)}g';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (final item in data.breakdown)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _formatLine(item),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            '총 ${data.totalAlcoholGrams.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 – 음주 위험도 분류 기준
// ─────────────────────────────────────────────────────────────────────────────

class _GuidelineTab extends StatelessWidget {
  const _GuidelineTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row + table – with left padding
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '*순수 알코올 양(g) 기준',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: _HeaderChip(label: '남성')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Center(child: _HeaderChip(label: '여성')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _GuidelineRow(
                  label: '적정',
                  bgColor: const Color(0xFFD4EFDF),
                  textColor: const Color(0xFF27AE60),
                  maleRange: '1~40g',
                  femaleRange: '1~20g',
                ),
                const SizedBox(height: 8),
                _GuidelineRow(
                  label: '저위험군',
                  bgColor: const Color(0xFFFEF9E7),
                  textColor: const Color(0xFFF39C12),
                  maleRange: '41~60g',
                  femaleRange: '21~40g',
                ),
                const SizedBox(height: 8),
                _GuidelineRow(
                  label: '고위험군',
                  bgColor: const Color(0xFFFEF0D9),
                  textColor: const Color(0xFFE67E22),
                  maleRange: '61~100g',
                  femaleRange: '41~60g',
                ),
                const SizedBox(height: 8),
                _GuidelineRow(
                  label: '매우 위험군',
                  bgColor: const Color(0xFFFDECEC),
                  textColor: const Color(0xFFE74C3C),
                  maleRange: '100g 초과',
                  femaleRange: '60g 초과',
                ),
              ],
            ),
          ),
          // Disclaimer
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '* 해당 기준은 최소한의 안전을 위한 가이드라인이며, 하루 1잔 이하의 음주 역시 유해할 수 있습니다.\n* 음주 시 안면 홍조 등의 증상이 나타나는 경우, 하루 10g 미만 섭취도 위험할 수 있습니다.',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.maleRange,
    required this.femaleRange,
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final String maleRange;
  final String femaleRange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            maleRange,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            femaleRange,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 – 순수 알코올 양 계산
// ─────────────────────────────────────────────────────────────────────────────

class _CalculationTab extends StatelessWidget {
  const _CalculationTab();

  // (drinkType id, portion label, ml, abv)
  static const List<(int, String, double, double)> _refDrinks = [
    (1, '1잔', 50.0, 0.165), // 소주
    (2, '1잔', 300.0, 0.05), // 맥주
    (4, '1잔', 150.0, 0.12), // 와인
    (5, '1잔', 200.0, 0.06), // 막걸리
    (6, '1잔', 30.0, 0.40), // 위스키
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formula box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('섭취량(ml)', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                const Text('X', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('알코올 도수', style: TextStyle(fontSize: 13)),
                    Container(
                      width: 64,
                      height: 1,
                      color: Colors.black87,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    const Text('100', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 10),
                const Text('X', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                const Text(
                  '0.8',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 2-column reference grid
          for (int i = 0; i < _refDrinks.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: _RefDrinkTile(_refDrinks[i])),
                  const SizedBox(width: 8),
                  if (i + 1 < _refDrinks.length)
                    Expanded(child: _RefDrinkTile(_refDrinks[i + 1]))
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RefDrinkTile extends StatelessWidget {
  const _RefDrinkTile(this.drink);

  /// (drinkType id, portion label, ml, abv)
  final (int, String, double, double) drink;

  @override
  Widget build(BuildContext context) {
    final (id, portion, ml, abv) = drink;
    final grams = ml * abv * 0.8;
    final name = getDrinkTypeName(id);
    final iconPath = getDrinkIconPath(id);
    final mlStr = ml.toStringAsFixed(0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(iconPath, width: 28, height: 28, fit: BoxFit.contain),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$name $portion ${mlStr}ml = ${grams.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
