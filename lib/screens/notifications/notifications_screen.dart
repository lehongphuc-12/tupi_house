import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../orders/order_history_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const _NotificationsLoginRequired();

    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thông báo'),
            if (provider.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softPink,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${provider.unreadCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: provider.markAllAsRead,
              child: const Text('Đọc tất cả'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _NotificationsBody(provider: provider),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  final NotificationProvider provider;

  const _NotificationsBody({required this.provider});

  List<_NotificationSection> _sections() {
    final groups = <String, List<AppNotification>>{};
    for (final notification in provider.notifications) {
      final key = _dateLabel(notification.createdAt);
      groups.putIfAbsent(key, () => <AppNotification>[]).add(notification);
    }
    return groups.entries
        .map((entry) => _NotificationSection(entry.key, entry.value))
        .toList();
  }

  String _dateLabel(DateTime value) {
    final date = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = today.difference(target).inDays;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      );
    }

    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return _NotificationMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Chưa thể tải thông báo',
        description: 'Không thể tải thông báo. Vui lòng kiểm tra kết nối và thử lại.',
      );
    }

    if (provider.notifications.isEmpty) {
      return const _NotificationEmptyState();
    }

    final sections = _sections();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          itemCount: sections.length,
          itemBuilder: (context, sectionIndex) {
            final section = sections[sectionIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(
                      section.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ...List.generate(section.notifications.length, (index) {
                    final notification = section.notifications[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == section.notifications.length - 1
                            ? 0
                            : 10,
                      ),
                      child: _NotificationTile(
                        notification: notification,
                        onTap: () => _onTap(context, provider, notification),
                        onDismiss: () =>
                            provider.deleteNotification(notification.id),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }
    if (!context.mounted) return;
    if (notification.orderId != null && notification.orderId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _icon {
    final status = notification.data['status']?.toString();
    if (status != null) return NotificationService.statusIcon(status);
    switch (notification.type) {
      case 'order_created':
        return Icons.receipt_long_outlined;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'promotion':
        return Icons.card_giftcard_outlined;
      case 'review':
        return Icons.star_outline_rounded;
      case 'account':
        return Icons.person_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get _accent {
    final status = notification.data['status']?.toString().toLowerCase();
    if (notification.type == 'order_cancelled' || status == 'cancelled') {
      return AppColors.error;
    }
    switch (status) {
      case 'confirmed':
      case 'shipping':
      case 'delivered':
        return AppColors.sageGreenDark;
      case 'pending':
        return AppColors.warning;
      default:
        return notification.type == 'promotion'
            ? AppColors.woodBrownDark
            : AppColors.primaryPink;
    }
  }

  Color get _accentSurface {
    if (_accent == AppColors.error) return AppColors.errorLight;
    if (_accent == AppColors.sageGreenDark) return AppColors.softGreen;
    if (_accent == AppColors.warning) return AppColors.warningLight;
    if (_accent == AppColors.woodBrownDark) return AppColors.lightCream;
    return AppColors.softPink;
  }

  String get _timeLabel {
    final date = notification.createdAt.toLocal();
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: notification.isRead ? AppColors.surface : AppColors.softPink,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: notification.isRead
                    ? AppColors.outlineSoft
                    : AppColors.primaryPinkLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _accentSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: _accent, size: 23),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: notification.isRead
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: AppColors.primaryPink,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _timeLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 126,
              height: 126,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.softPink, AppColors.lightCream],
                ),
                shape: BoxShape.circle,
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 60,
                    color: AppColors.primaryPink,
                  ),
                  Positioned(
                    top: 24,
                    right: 22,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 22,
                      color: AppColors.warning,
                    ),
                  ),
                  Positioned(
                    bottom: 22,
                    left: 23,
                    child: Icon(
                      Icons.local_florist_outlined,
                      size: 24,
                      color: AppColors.sageGreenDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa có thông báo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cập nhật về đơn hàng và ưu đãi của Tupi House sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _NotificationMessage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: AppColors.muted),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsLoginRequired extends StatelessWidget {
  const _NotificationsLoginRequired();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Text('Thông báo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                size: 66,
                color: AppColors.muted,
              ),
              const SizedBox(height: 18),
              const Text(
                'Đăng nhập để xem thông báo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn sẽ nhận được cập nhật khi trạng thái đơn hàng thay đổi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginScreen(returnToPrevious: true),
                  ),
                ),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSection {
  final String label;
  final List<AppNotification> notifications;

  const _NotificationSection(this.label, this.notifications);
}
