import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_card.dart';
import '../../widgets/star_rating_bar.dart';
import '../../widgets/review_card.dart';
import '../../models/cart.dart';
import 'add_review_bottom_sheet.dart';

class OptimizedProductDetailScreen extends StatefulWidget {
  final Product product;
  const OptimizedProductDetailScreen({super.key, required this.product});

  @override
  State<OptimizedProductDetailScreen> createState() => _OptimizedProductDetailScreenState();
}

class _OptimizedProductDetailScreenState extends State<OptimizedProductDetailScreen> {
  int _quantity = 1;
  late Product _product;
  int _activeImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addToCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItem = CartItem(
      productId: _product.id,
      title: _product.title,
      price: _product.price,
      thumbnail: _product.thumbnail,
      quantity: _quantity,
    );

    try {
      await cartProvider.addToCart(cartItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào giỏ hàng! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    }
  }

  Widget _buildImageGallery(bool isWide) {
    final images = _product.images.isNotEmpty ? _product.images : [_product.thumbnail];
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (idx) {
            setState(() {
              _activeImageIndex = idx;
            });
          },
          itemBuilder: (context, index) {
            return ProductImage(path: images[index], iconSize: 80);
          },
        ),
        // Indicators
        if (images.length > 1)
          Positioned(
            bottom: isWide ? 16 : 48, // offset transform shift
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _activeImageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.pastelPinkDark : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        // Sale Badge
        if (_product.isOnSale)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'GIẢM GIÁ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestedProducts() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final products = provider.products.where((p) => p.id != _product.id).take(4).toList();
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Sản phẩm gợi ý 🌸',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.pastelPinkDark),
              ),
            ),
            SizedBox(
              height: 260,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 150,
                    child: ProductCard(
                      product: products[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OptimizedProductDetailScreen(product: products[index]),
                          ),
                        );
                      },
                      isFavorite: false,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, provider, _) {
        final reviews = provider.reviews;
        final auth = context.watch<AuthProvider>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đánh giá & Nhận xét',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.pastelPinkDark),
                  ),
                  if (auth.isLoggedIn && !provider.userHasReviewed)
                    TextButton.icon(
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Viết đánh giá'),
                      onPressed: () async {
                        final success = await AddReviewBottomSheet.show(context, _product.id);
                        if (success == true) {
                          // Refresh product rating from Firestore (which has been updated asynchronously)
                          // ignore: use_build_context_synchronously
                          context.read<ProductProvider>().fetchProducts();
                        }
                      },
                    ),
                ],
              ),
            ),
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (reviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 40, color: AppColors.muted),
                      SizedBox(height: 8),
                      Text(
                        'Chưa có đánh giá nào cho sản phẩm này.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Summary card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RatingSummary(
                  average: provider.averageRating,
                  total: reviews.length,
                  distribution: provider.ratingDistribution,
                ),
              ),
              const SizedBox(height: 20),
              // List
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return ReviewCard(review: reviews[index]);
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _infoSection(bool isWide) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isWide ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: isWide ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.title,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.25),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_product.isOnSale) ...[
                          Text(
                            formatVnd(_product.price.toDouble()),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          formatVnd((_product.salePrice ?? _product.price).toDouble()),
                          style: const TextStyle(fontSize: 24, color: AppColors.pastelPinkDark, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Real-time rating widget from Provider
                    Consumer<ReviewProvider>(
                      builder: (context, rp, _) {
                        final avg = rp.reviews.isEmpty ? _product.rating : rp.averageRating;
                        final count = rp.reviews.length;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                              const SizedBox(width: 4),
                              Text('($count)', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('Mô tả sản phẩm', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                Html(
                  data: _product.description,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      fontSize: FontSize(15.0),
                      color: AppColors.muted,
                      lineHeight: const LineHeight(1.6),
                    ),
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              if (_quantity > 1) _quantity--;
                            }),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.remove, size: 20, color: AppColors.pastelGreenDark),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.pastelGreenDark)),
                          ),
                          InkWell(
                            onTap: () => setState(() => _quantity++),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.add, size: 20, color: AppColors.pastelGreenDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const Divider(height: 1, color: Color(0xFFF0E8EB)),
          const SizedBox(height: 8),
          _buildReviewsSection(),
          const Divider(height: 1, color: Color(0xFFF0E8EB)),
          const SizedBox(height: 16),
          _buildSuggestedProducts(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    // Wrapper local ChangeNotifierProvider for ReviewProvider to guarantee it works without modifying main.dart
    return ChangeNotifierProvider<ReviewProvider>(
      create: (_) => ReviewProvider()..fetchReviews(_product.id, userId: auth.isLoggedIn ? auth.currentUser!.id : null),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F9),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border_rounded, color: AppColors.pastelPinkDark, size: 22),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng yêu thích đang phát triển')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final imageSection = AspectRatio(
              aspectRatio: isWide ? 1 : 1.05,
              child: _buildImageGallery(isWide),
            );

            if (isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 110),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: imageSection,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(flex: 6, child: _infoSection(true)),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  imageSection,
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: _infoSection(false),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng cộng', style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        formatVnd(((_product.salePrice ?? _product.price) * _quantity).toDouble()),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.pastelPinkDark),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pastelPinkDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: const Text('Thêm vào giỏ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _addToCart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
