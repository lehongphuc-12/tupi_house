import 'package:flutter/material.dart';

class StarRatingBar extends StatelessWidget {
  final double rating;
  final double starSize;
  final ValueChanged<double>? onRatingChanged;
  final bool isInteractive;
  final Color starColor;

  const StarRatingBar({
    super.key,
    required this.rating,
    this.starSize = 18,
    this.onRatingChanged,
    this.isInteractive = false,
    this.starColor = const Color(0xFFFFB800),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đánh giá ${rating.toStringAsFixed(1)} trên 5 sao',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final starValue = index + 1;
          final iconData = rating >= starValue
              ? Icons.star_rounded
              : rating >= starValue - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded;
          final icon = Icon(iconData, size: starSize, color: starColor);

          if (!isInteractive || onRatingChanged == null) {
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: icon,
            );
          }

          return Semantics(
            button: true,
            label: 'Chọn $starValue sao',
            child: Tooltip(
              message: '$starValue sao',
              child: InkResponse(
                radius: 22,
                onTap: () => onRatingChanged!(starValue.toDouble()),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: icon),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
