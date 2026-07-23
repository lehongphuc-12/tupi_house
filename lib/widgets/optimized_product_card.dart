import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import 'product_image.dart';

class OptimizedProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const OptimizedProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<OptimizedProductCard> createState() => _OptimizedProductCardState();
}

class _OptimizedProductCardState extends State<OptimizedProductCard> {
  bool _isHovered = false;

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(price);
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final isFavorite = wishlistProvider.isFavorite(widget.product.id);
    final isFlashSale = widget.product.isCurrentlyFlashSale;
    final displayPrice = isFlashSale
        ? widget.product.flashSalePrice!
        : (widget.product.salePrice ?? widget.product.price);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0.0, _isHovered ? -3.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryPinkLight
                  : AppColors.outlineSoft,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.04),
                blurRadius: _isHovered ? 16 : 12,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Stack Container
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Product Thumbnail with Hero Animation
                    AnimatedScale(
                      scale: _isHovered ? 1.01 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(19)),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColors.surfaceVariant,
                          child: Hero(
                            tag: 'product-img-${widget.product.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: ProductImage(
                                path: widget.product.thumbnail,
                                fit: BoxFit.cover,
                                iconSize: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Sale Badge (Top Left)
                    if (isFlashSale)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.saleRedPink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'SALE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (widget.product.isOnSale)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.saleRedPink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${_calculateDiscount()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                    // Rating Badge (Top Left - positioned after sale badge)
                    if (widget.product.rating > 0 && !isFlashSale && !widget.product.isOnSale)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.product.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Favorite Button (Top Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            final auth = context.read<AuthProvider>();
                            if (!auth.isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen(
                                        returnToPrevious: true)),
                              );
                              return;
                            }
                            await wishlistProvider.toggleWishlist(widget.product);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? AppColors.primaryPinkLight
                                  : AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: isFavorite
                                  ? AppColors.primaryPink
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Text Info Container
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Price Row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _formatPrice(displayPrice),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryPink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (isFlashSale || widget.product.isOnSale) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatPrice(widget.product.price),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDiscount() {
    if (widget.product.salePrice == null || widget.product.price <= 0) {
      return '0';
    }
    final discount =
        ((widget.product.price - widget.product.salePrice!) /
                widget.product.price *
                100)
            .round();
    return discount.clamp(0, 100).toString();
  }
}
