import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';

/// 월 음주 목표 입력/수정 바텀 시트
class GoalEditSheet extends ConsumerStatefulWidget {
  const GoalEditSheet({
    super.key,
    this.initialBudget,
    this.initialAlcohol,
    required this.monthLabel,
  });

  final int? initialBudget;
  final double? initialAlcohol;
  final String monthLabel; // e.g. "2월"

  @override
  ConsumerState<GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends ConsumerState<GoalEditSheet> {
  final _budgetController = TextEditingController();
  final _alcoholController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBudget != null) {
      _budgetController.text = widget.initialBudget.toString();
    }
    if (widget.initialAlcohol != null) {
      _alcoholController.text = widget.initialAlcohol!.toStringAsFixed(
        widget.initialAlcohol! % 1 == 0 ? 0 : 1,
      );
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _alcoholController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final budget = int.tryParse(_budgetController.text);
    final alcohol = double.tryParse(_alcoholController.text);
    return (budget != null && budget > 0) || (alcohol != null && alcohol > 0);
  }

  Future<void> _save() async {
    final budget = int.tryParse(_budgetController.text);
    final alcohol = double.tryParse(_alcoholController.text);

    if (budget == null && alcohol == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.updateMonthlyGoal(
        budget: (budget != null && budget > 0) ? budget : null,
        alcohol: (alcohol != null && alcohol > 0) ? alcohol : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.initialBudget != null || widget.initialAlcohol != null;
    final monthNum = DateTime.now().month;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              '음주 목표 설정',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            // Budget input
            _GoalInputRow(
              label: '$monthNum월 술자리 예산',
              unit: '원',
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            // Alcohol input
            _GoalInputRow(
              label: '$monthNum월 목표 음주량',
              unit: '병',
              controller: _alcoholController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 48),
            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_canSave && !_isSaving) ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? Colors.black : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? '수정하기' : '입력하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _GoalInputRow extends StatelessWidget {
  const _GoalInputRow({
    required this.label,
    required this.unit,
    required this.controller,
    required this.keyboardType,
    required this.inputFormatters,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textAlign: TextAlign.end,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? Colors.black : Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
