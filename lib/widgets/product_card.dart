import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onToggleFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: ProductImage(path: product.thumbnail),
              ),
            ),

            // Thông tin
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(10, 6, 10, 8), // Giảm padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            formatVnd(product.price.toDouble()),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.pastelPinkDark,
                            ),
                          ),
                        ),

                        // Nút nhỏ gọn
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onToggleFavorite != null)
                              _FavoriteButton(
                                onPressed: onToggleFavorite!,
                                isFavorite: isFavorite,
                              ),
                            const SizedBox(width: 4),
                            if (onAddToCart != null)
                              _CartButton(onPressed: onAddToCart!),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Nút siêu gọn
class _CartButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: AppColors.softGreen,
        foregroundColor: AppColors.pastelGreenDark,
        iconSize: 17,
        minimumSize: const Size(30, 30),
        padding: EdgeInsets.zero,
      ),
      icon: const Icon(Icons.add_shopping_cart_rounded),
      onPressed: onPressed,
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isFavorite;

  const _FavoriteButton({required this.onPressed, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: AppColors.softPink,
        foregroundColor: AppColors.pastelPinkDark,
        iconSize: 17,
        minimumSize: const Size(30, 30),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      onPressed: onPressed,
    );
  }
}
