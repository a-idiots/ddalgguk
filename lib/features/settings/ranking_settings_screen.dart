import 'package:ddalgguk/features/auth/domain/models/app_user.dart';
import 'package:ddalgguk/features/ranking/data/providers/ranking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/providers/auth_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';

class RankingSettingsScreen extends ConsumerWidget {
  const RankingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '랭킹 설정',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SettingsSectionDivider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '과음관리구역에서의 노출 방식을 설정하세요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const _RankingToggleTile(
            field: _RankingField.rankingPermission,
            title: '랭킹탭 노출',
            description: '과음관리구역에 내 정보가 표시됩니다.',
          ),
          const SettingsSectionDivider(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '※ 노출을 끄면 랭킹 집계에는 포함되지만, 다른 유저에게 내 정보가 가려집니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

enum _RankingField { rankingPermission }

class _RankingToggleTile extends ConsumerStatefulWidget {
  const _RankingToggleTile({
    required this.field,
    required this.title,
    required this.description,
  });

  final _RankingField field;
  final String title;
  final String description;

  @override
  ConsumerState<_RankingToggleTile> createState() => _RankingToggleTileState();
}

class _RankingToggleTileState extends ConsumerState<_RankingToggleTile> {
  bool _isUpdating = false;

  bool _currentValue(AppUser? user) {
    if (user == null) {
      return true;
    }
    return user.rankingPermission ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        final isEnabled = _currentValue(user);
        return _buildTile(isEnabled: isEnabled);
      },
      loading: () => _buildLoadingTile(),
      error: (_, __) => _buildErrorTile(),
    );
  }

  Widget _buildTile({required bool isEnabled}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isUpdating
                  ? null
                  : () async {
                      setState(() => _isUpdating = true);
                      try {
                        final repo = ref.read(authRepositoryProvider);
                        final newValue = !isEnabled;
                        // users/{uid} 업데이트 (클라이언트 필터용)
                        await repo.updateRankingPermissions(
                          rankingPermission: newValue,
                        );

                        // rankings/{uid} 업데이트 (DB 쿼리 필터용)
                        final uid = ref.read(currentUserProvider).value?.uid;
                        if (uid != null) {
                          await ref
                              .read(rankingServiceProvider)
                              .updatePermissions(
                                uid,
                                rankingPermission: newValue,
                              );
                        }

                        ref.invalidate(currentUserProvider);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('설정 변경 실패: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isUpdating = false);
                        }
                      }
                    },
              child: Opacity(
                opacity: _isUpdating ? 0.5 : 1.0,
                child: Container(
                  width: 51,
                  height: 31,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFFFF6B6B)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(15.5),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: isEnabled
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 27,
                      height: 27,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorTile() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          '설정을 불러올 수 없습니다',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
