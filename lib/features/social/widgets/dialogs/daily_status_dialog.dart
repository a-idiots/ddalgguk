import 'package:ddalgguk/core/constants/app_colors.dart';
import 'package:ddalgguk/features/social/domain/models/daily_status.dart';
import 'package:ddalgguk/features/social/data/providers/friend_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 일일 상태 추가/수정 다이얼로그
class DailyStatusDialog extends ConsumerStatefulWidget {
  const DailyStatusDialog({super.key});

  @override
  ConsumerState<DailyStatusDialog> createState() => _DailyStatusDialogState();
}

class _DailyStatusDialogState extends ConsumerState<DailyStatusDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitStatus() async {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상태 메시지를 입력해주세요')));
      return;
    }

    if (message.length > DailyStatus.maxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('상태 메시지는 최대 ${DailyStatus.maxLength}자까지 입력 가능합니다'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final friendService = ref.read(friendServiceProvider);
      await friendService.updateMyDailyStatus(message);

      if (mounted) {
        // 친구 목록 새로고침
        ref.invalidate(friendsProvider);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('상태가 업데이트되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상태 메시지를 남겨보세요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '24시간 후 자동으로 사라집니다',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLength: DailyStatus.maxLength,
              decoration: InputDecoration(
                hintText: '예: 오늘도 화이팅!',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText:
                    '${_controller.text.length}/${DailyStatus.maxLength}',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('등록'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
