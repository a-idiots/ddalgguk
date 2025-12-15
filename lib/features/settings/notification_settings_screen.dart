import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddalgguk/core/services/notification_config.dart';
import 'package:ddalgguk/core/providers/notification_provider.dart';
import 'package:ddalgguk/core/widgets/settings_widgets.dart';

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.recordAlarm:
        return '음주 기록 알림';
      case NotificationType.socialAlarm:
        return '소셜 알림';
      case NotificationType.recapAlarm:
        return 'Recap 알림';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.recordAlarm:
        return '매일 밤 9시에 음주 기록 업데이트를 알려드려요.';
      case NotificationType.socialAlarm:
        return '친구들의 소식을 알려드립니다';
      case NotificationType.recapAlarm:
        return '월간 음주 리포트가 완성되면 알려드려요.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '알림 설정',
          style: TextStyle(
            fontFamily: 'Inter',
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
              '받고 싶은 알림을 선택하세요',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          ...NotificationType.values
              .where((type) => type != NotificationType.socialAlarm)
              .map((type) {
            return _NotificationToggleTile(
              type: type,
              title: _getNotificationTypeName(type),
              description: _getNotificationTypeDescription(type),
            );
          }),
          const SettingsSectionDivider(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '※ 알림을 받으려면 기기 설정에서 알림 권한을 허용해주세요.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NotificationToggleTile extends ConsumerStatefulWidget {
  const _NotificationToggleTile({
    required this.type,
    required this.title,
    required this.description,
  });

  final NotificationType type;
  final String title;
  final String description;

  @override
  ConsumerState<_NotificationToggleTile> createState() =>
      _NotificationToggleTileState();
}

class _NotificationToggleTileState
    extends ConsumerState<_NotificationToggleTile> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final isEnabledAsync = ref.watch(
      isNotificationEnabledProvider(widget.type),
    );

    return isEnabledAsync.when(
      data: (isEnabled) {
        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontFamily: 'Inter',
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
                          setState(() {
                            _isUpdating = true;
                          });

                          try {
                            final toggleFn = ref.read(
                              toggleNotificationProvider,
                            );
                            await toggleFn(widget.type, !isEnabled);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('알림 설정 변경 실패: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                _isUpdating = false;
                              });
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
      },
      loading: () => Container(
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
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontFamily: 'Inter',
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
      ),
      error: (error, _) => Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            '알림 설정을 불러올 수 없습니다',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
