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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData iconData;
        if (rating >= starValue) {
          iconData = Icons.star_rounded;
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half_rounded;
        } else {
          iconData = Icons.star_outline_rounded;
        }

        final starIcon = Icon(
          iconData,
          size: starSize,
          color: starColor,
        );

        if (isInteractive && onRatingChanged != null) {
          return GestureDetector(
            onTap: () => onRatingChanged!(starValue.toDouble()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: starIcon,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(right: 2.0),
          child: starIcon,
        );
      }),
    );
  }
}
