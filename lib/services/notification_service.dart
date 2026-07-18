import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Service lắng nghe thay đổi trạng thái đơn hàng và hiển thị thông báo in-app
class NotificationService {
  static StreamSubscription<QuerySnapshot>? _subscription;
  static final Map<String, String> _lastStatuses = {};

  static String _statusLabel(String status) {
    const labels = {
      'pending': 'Chờ xác nhận ⏳',
      'confirmed': 'Đã xác nhận ✅',
      'shipping': 'Đang giao hàng 🚚',
      'delivered': 'Đã giao thành công 🎉',
      'cancelled': 'Đã hủy đơn ❌',
    };
    return labels[status] ?? status;
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.celebration_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Bắt đầu lắng nghe thay đổi đơn hàng của user
  static void startListening({
    required String userId,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) {
    _subscription?.cancel();
    _lastStatuses.clear();

    _subscription = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final orderId = change.doc.id;
        final newStatus = data['status'] as String? ?? 'pending';
        final shortId = orderId.length >= 6
            ? orderId.substring(0, 6).toUpperCase()
            : orderId.toUpperCase();

        if (change.type == DocumentChangeType.added) {
          _lastStatuses[orderId] = newStatus;
        } else if (change.type == DocumentChangeType.modified) {
          final lastStatus = _lastStatuses[orderId];
          if (lastStatus != null && lastStatus != newStatus) {
            _showNotification(
              messengerKey: messengerKey,
              orderId: shortId,
              newStatus: newStatus,
            );
          }
          _lastStatuses[orderId] = newStatus;
        }
      }
    });
  }

  static void _showNotification({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required String orderId,
    required String newStatus,
  }) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _statusIcon(newStatus),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cập nhật đơn hàng',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đơn #$orderId: ${_statusLabel(newStatus)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dừng lắng nghe
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _lastStatuses.clear();
  }
}
