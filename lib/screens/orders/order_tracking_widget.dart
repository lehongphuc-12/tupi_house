import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Timeline stepper hiển thị tiến trình đơn hàng
class OrderTrackingWidget extends StatelessWidget {
  final String currentStatus;

  const OrderTrackingWidget({super.key, required this.currentStatus});

  static const _steps = [
    _TrackingStep(
      status: 'pending',
      label: 'Chờ xác nhận',
      sublabel: 'Đơn hàng đang chờ shop xác nhận',
      icon: Icons.receipt_long_outlined,
    ),
    _TrackingStep(
      status: 'confirmed',
      label: 'Đã xác nhận',
      sublabel: 'Shop đã xác nhận và đang chuẩn bị hàng',
      icon: Icons.inventory_2_outlined,
    ),
    _TrackingStep(
      status: 'shipping',
      label: 'Đang giao hàng',
      sublabel: 'Đơn hàng đang trên đường giao đến bạn',
      icon: Icons.local_shipping_outlined,
    ),
    _TrackingStep(
      status: 'delivered',
      label: 'Đã giao hàng',
      sublabel: 'Bạn đã nhận được hàng thành công 🎉',
      icon: Icons.check_circle_outline_rounded,
    ),
  ];

  int _currentIndex() {
    if (currentStatus == 'cancelled') return -1;
    return _steps.indexWhere((s) => s.status == currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'cancelled') {
      return _CancelledTracker();
    }

    final currentIdx = _currentIndex();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theo dõi đơn hàng',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          ...List.generate(_steps.length, (i) {
            final step = _steps[i];
            final isDone = i < currentIdx;
            final isCurrent = i == currentIdx;
            final isLast = i == _steps.length - 1;
            return _StepRow(
              step: step,
              isDone: isDone,
              isCurrent: isCurrent,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final _TrackingStep step;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _StepRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    Color lineColor;
    Color labelColor;
    Widget dot;

    if (isDone) {
      lineColor = AppColors.pastelGreenDark;
      labelColor = AppColors.ink;
      dot = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.pastelGreenDark, width: 2),
        ),
        child: Icon(Icons.check_rounded,
            color: AppColors.pastelGreenDark, size: 18),
      );
    } else if (isCurrent) {
      lineColor = const Color(0xFFE8E2E5);
      labelColor = AppColors.pastelPinkDark;
      dot = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.softPink,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.pastelPinkDark, width: 2),
        ),
        child: Icon(step.icon, color: AppColors.pastelPinkDark, size: 18),
      );
    } else {
      lineColor = const Color(0xFFE8E2E5);
      labelColor = AppColors.muted;
      dot = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0D8DB), width: 2),
        ),
        child: Icon(step.icon, color: const Color(0xFFCBC4C7), size: 18),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: dot + vertical line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                dot,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right: label + sublabel
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 8, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  if (isCurrent || isDone) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.sublabel,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.cancel_outlined,
                color: Colors.redAccent, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng đã bị hủy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Đơn hàng này không còn được xử lý nữa.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStep {
  final String status;
  final String label;
  final String sublabel;
  final IconData icon;

  const _TrackingStep({
    required this.status,
    required this.label,
    required this.sublabel,
    required this.icon,
  });
}
