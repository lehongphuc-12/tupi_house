import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge hiển thị trạng thái đơn hàng với màu sắc phù hợp
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool large;

  const OrderStatusBadge({super.key, required this.status, this.large = false});

  static String label(String status) {
    const map = {
      'pending': 'Chờ xác nhận',
      'confirmed': 'Đã xác nhận',
      'shipping': 'Đang giao hàng',
      'delivered': 'Đã giao hàng',
      'cancelled': 'Đã hủy',
    };
    return map[status] ?? status;
  }

  static Color bgColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFF3E0);
      case 'confirmed':
        return const Color(0xFFE3F2FD);
      case 'shipping':
        return const Color(0xFFF3E5F5);
      case 'delivered':
        return AppColors.softGreen;
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.shade100;
    }
  }

  static Color fgColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE65100);
      case 'confirmed':
        return const Color(0xFF1565C0);
      case 'shipping':
        return const Color(0xFF6A1B9A);
      case 'delivered':
        return AppColors.pastelGreenDark;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return AppColors.muted;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = fgColor(status);
    final bg = bgColor(status);
    final fontSize = large ? 13.0 : 11.5;
    final iconSize = large ? 15.0 : 12.0;
    final hPad = large ? 12.0 : 9.0;
    final vPad = large ? 6.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: iconSize, color: fg),
          const SizedBox(width: 5),
          Text(
            label(status),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
