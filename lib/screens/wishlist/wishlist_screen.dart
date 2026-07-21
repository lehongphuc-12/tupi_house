import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart.dart';
import '../../models/product.dart';
import '../../models/wishlist.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

import '../product/optimized_product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách yêu thích'),
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (wishlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (wishlistProvider.errorMessage != null) {
            return Center(
              child: Text(
                wishlistProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final items = wishlistProvider.items;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.softPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: AppColors.pastelPinkDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chưa có sản phẩm yêu thích',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy khám phá và lưu những sản phẩm bạn thích nhé! 🌸',
                    style: TextStyle(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return InkWell(
                onTap: () => _navigateToDetail(context, item.productId),
                borderRadius: BorderRadius.circular(18),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFF0E8EB)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.thumbnail.startsWith('http')
                              ? Image.network(
                                  item.thumbnail,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _fallbackImage(),
                                )
                              : Image.asset(
                                  item.thumbnail,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _fallbackImage(),
                                ),
                        ),
                        const SizedBox(width: 14),

                        // Title, Category, Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.categoryName,
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatVnd(item.price.toDouble()),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pastelPinkDark,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () async {
                                final product = Product(
                                  id: item.productId,
                                  title: item.title,
                                  price: item.price,
                                  thumbnail: item.thumbnail,
                                  images: [],
                                  description: '',
                                  categoryId: '',
                                  categoryName: item.categoryName,
                                );
                                await wishlistProvider.toggleWishlist(product);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart_rounded,
                                  color: AppColors.pastelGreenDark),
                              onPressed: () => _addToCart(context, item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.softPink,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AppColors.pastelPinkDark),
    );
  }

  Future<void> _navigateToDetail(BuildContext context, String productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close dialog

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final product = Product.fromJson(data);

        Navigator.of(context).push(
          MaterialPageRoute(  
            builder: (_) => OptimizedProductDetailScreen(product: product),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin sản phẩm')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải sản phẩm: $e')),
        );
      }
    }
  }

  void _addToCart(BuildContext context, WishlistItem item) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItem = CartItem(
      productId: item.productId,
      title: item.title,
      price: item.price,
      thumbnail: item.thumbnail,
      quantity: 1,
    );

    try {
      await cartProvider.addToCart(cartItem);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào giỏ hàng! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    }
  }
}
