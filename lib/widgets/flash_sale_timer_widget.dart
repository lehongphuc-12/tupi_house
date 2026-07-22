import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FlashSaleTimerWidget extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback? onTimerFinished;

  const FlashSaleTimerWidget({
    super.key,
    required this.endTime,
    this.onTimerFinished,
  });

  @override
  State<FlashSaleTimerWidget> createState() => _FlashSaleTimerWidgetState();
}

class _FlashSaleTimerWidgetState extends State<FlashSaleTimerWidget> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
        });
      }
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (now.isAfter(widget.endTime)) {
      _timeLeft = Duration.zero;
      _timer.cancel();
      if (widget.onTimerFinished != null) {
        widget.onTimerFinished!();
      }
    } else {
      _timeLeft = widget.endTime.difference(now);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.pastelPinkDark,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative || _timeLeft == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off_outlined, color: Colors.grey, size: 16),
            SizedBox(width: 6),
            Text(
              'Đã kết thúc',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final hours = _twoDigits(_timeLeft.inHours);
    final minutes = _twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = _twoDigits(_timeLeft.inSeconds.remainder(60));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5), // Soft lavender pink
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD1DF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Colors.orange, size: 22),
              SizedBox(width: 4),
              Text(
                'FLASH SALE',
                style: TextStyle(
                  color: AppColors.pastelPinkDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          _buildTimeBox(hours, 'Giờ'),
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 4, bottom: 16),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.pastelPinkDark,
              ),
            ),
          ),
          _buildTimeBox(minutes, 'Phút'),
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 4, bottom: 16),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.pastelPinkDark,
              ),
            ),
          ),
          _buildTimeBox(seconds, 'Giây'),
        ],
      ),
    );
  }
}
