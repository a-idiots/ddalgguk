import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/ranking/data/providers/ranking_providers.dart';
import 'package:ddalgguk/features/ranking/widgets/ranking_profile_dialog.dart';
import 'package:ddalgguk/shared/widgets/bottom_handle_dialogue.dart';
import 'package:ddalgguk/shared/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingTab extends ConsumerStatefulWidget {
  const RankingTab({super.key});

  @override
  ConsumerState<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends ConsumerState<RankingTab> {
  bool _isWeekly = true;

  Future<void> _onRefresh() async {
    if (_isWeekly) {
      ref.invalidate(weeklyRankingProvider);
      await ref.read(weeklyRankingProvider.future);
    } else {
      ref.invalidate(monthlyRankingProvider);
      await ref.read(monthlyRankingProvider.future);
    }
  }

  String _periodDisplay() {
    final now = DateTime.now();
    if (_isWeekly) {
      final weekInMonth = ((now.day - 1) ~/ 7) + 1;
      return '${now.month}월 $weekInMonth주';
    }
    return '${now.year}년 ${now.month}월';
  }

  List<int> _computeRanks(List<RankingEntryWithUser> entries) {
    final ranks = List<int>.filled(entries.length, 0);
    for (var i = 0; i < entries.length; i++) {
      if (i == 0 || entries[i].amount != entries[i - 1].amount) {
        ranks[i] = i + 1;
      } else {
        ranks[i] = ranks[i - 1];
      }
    }
    return ranks;
  }


  @override
  Widget build(BuildContext context) {
    final rankingAsync = _isWeekly
        ? ref.watch(weeklyRankingProvider)
        : ref.watch(monthlyRankingProvider);

    return Column(
      children: [
        _buildPillToggle(),
        Expanded(
          child: rankingAsync.when(
            data: _buildContent,
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      '랭킹을 불러오지 못했습니다\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _onRefresh,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Pill 토글

  Widget _buildPillToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 16, 60, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildPill(label: 'week', selected: _isWeekly, onTap: () {
                setState(() => _isWeekly = true);
              }),
            ),
            Expanded(
              child: _buildPill(label: 'month', selected: !_isWeekly, onTap: () {
                setState(() => _isWeekly = false);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: selected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : const BoxDecoration(color: Colors.transparent),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.black : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // 실제 랭킹 내역

  Widget _buildContent(List<RankingEntryWithUser> entries) {
    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryPink,
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Text('랭킹에 표시할 유저가 없습니다.\n나의 기록을 추가해보세요!',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalGrams = entries.fold<double>(
      0,
      (acc, e) => acc + e.displayGrams,
    );
    final ranks = _computeRanks(entries);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primaryPink,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: entries.length + 1, // +1 for WARNING header
        separatorBuilder: (_, index) {
          if (index == 0) {
            return const SizedBox.shrink();
          }
          return Divider(height: 1, color: Colors.grey.shade100);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(totalGrams);
          }
          final i = index - 1;
          return _buildRow(entries[i], ranks[i]);
        },
      ),
    );
  }

  // WARNING 헤더

  Widget _buildHeader(double totalGrams) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'WARNING',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _periodDisplay(),
            style: TextStyle(fontSize: 17, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            '딸꾹 유저 총 음주량 ${totalGrams.toStringAsFixed(1)}g',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── 순위 행 ───────────────────────────────────────────────────────────────

  Widget _buildRow(RankingEntryWithUser entry, int rank) {
    return InkWell(
      onTap: () => showBottomHandleDialogue(
        context: context,
        child: RankingProfileDialog(entry: entry),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // 등수
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      rank <= 3 ? FontWeight.bold : FontWeight.normal,
                  color: rank <= 3 ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 프로필 아바타
            ProfileAvatar(
              profilePhoto: entry.profilePhoto,
              uid: entry.uid,
              size: 44,
            ),
            const SizedBox(width: 12),
            // 닉네임 + 아이디
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.customId != null && entry.customId!.isNotEmpty)
                    Text(
                      '@${entry.customId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            // 알코올량
            Text(
              '${entry.displayGrams.toStringAsFixed(1)}g',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
