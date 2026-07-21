import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget hiển thị sao đánh giá (read-only hoặc interactive)
class StarRatingBar extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final ValueChanged<double>? onRatingChanged; // null = read-only
  final bool showLabel;

  const StarRatingBar({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.filledColor = Colors.amber,
    this.emptyColor = const Color(0xFFDDDDDD),
    this.onRatingChanged,
    this.showLabel = false,
  });

  bool get isInteractive => onRatingChanged != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(starCount, (i) {
          final starValue = i + 1.0;
          final filled = rating >= starValue;
          final halfFilled = !filled && rating >= starValue - 0.5;

          IconData icon;
          Color color;
          if (filled) {
            icon = Icons.star_rounded;
            color = filledColor;
          } else if (halfFilled) {
            icon = Icons.star_half_rounded;
            color = filledColor;
          } else {
            icon = Icons.star_outline_rounded;
            color = emptyColor;
          }

          final star = Icon(icon, size: size, color: color);

          if (isInteractive) {
            return GestureDetector(
              onTap: () => onRatingChanged!(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: star,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: star,
          );
        }),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w700,
              color: filledColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget tóm tắt rating tổng quan (dùng trong Product Detail)
class RatingSummary extends StatelessWidget {
  final double average;
  final int total;
  final Map<int, int> distribution; // {5: count, 4: count, ...}

  const RatingSummary({
    super.key,
    required this.average,
    required this.total,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: big number
        Column(
          children: [
            Text(
              average.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            StarRatingBar(rating: average, size: 18),
            const SizedBox(height: 4),
            Text(
              '$total đánh giá',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(width: 20),
        // Right: distribution bars
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count = distribution[star] ?? 0;
              final pct = total > 0 ? count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$star',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        size: 12, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 24,
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
