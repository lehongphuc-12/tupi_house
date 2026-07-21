import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/cart.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/optimized_product_card.dart';
import '../../widgets/review_card.dart';
import '../../widgets/star_rating_bar.dart';
import '../cart/cart_screen.dart';
import '../login_screen.dart';
import 'add_review_bottom_sheet.dart';

class OptimizedProductDetailScreen extends StatefulWidget {
  final Product product;

  const OptimizedProductDetailScreen({super.key, required this.product});

  @override
  State<OptimizedProductDetailScreen> createState() =>
      _OptimizedProductDetailScreenState();
}

class _OptimizedProductDetailScreenState
    extends State<OptimizedProductDetailScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadReviews(widget.product.id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(price);
  }

  void _addToCart() {
    final cart = context.read<CartProvider>();
    final cartItem = CartItem(
      productId: widget.product.id,
      title: widget.product.title,
      price: widget.product.salePrice ?? widget.product.price,
      thumbnail: widget.product.thumbnail,
      quantity: _quantity,
    );
    cart.addToCart(cartItem);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('✅ Đã thêm $_quantity sản phẩm vào giỏ hàng!')),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: const Text('Xem giỏ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _buyNow() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    _addToCart();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isFavorite = wishlist.isFavorite(widget.product.id);
    final reviewProvider = context.watch<ReviewProvider>();
    final reviews = reviewProvider.reviews;
    
    final productProvider = context.watch<ProductProvider>();
    final similarProducts = productProvider.products
        .where((p) =>
            p.categoryId == widget.product.categoryId &&
            p.id != widget.product.id)
        .take(10)
        .toList();

    final displayPrice = widget.product.salePrice ?? widget.product.price;
    final totalAmount = displayPrice * _quantity;

    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.thumbnail];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar với Image Gallery PageView & Hero animation ──────────────
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: index == 0
                            ? 'product-img-${widget.product.id}'
                            : 'product-img-${widget.product.id}-$index',
                        child: images[index].isNotEmpty
                            ? Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      );
                    },
                  ),

                  // Carousel Indicators using AnimatedContainer
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isSelected = _currentImageIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isSelected ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.pastelPinkDark
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : AppColors.ink,
                  ),
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    if (!auth.isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      return;
                    }
                    await wishlist.toggleWishlist(widget.product);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.ink),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          // ── Product Content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SALE Badge & Category Tag
                  Row(
                    children: [
                      if (widget.product.isOnSale)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.softPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.product.categoryName.isNotEmpty
                              ? widget.product.categoryName
                              : 'Decor',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.pastelPinkDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.product.stock > 0)
                        Text(
                          'Còn ${widget.product.stock} sản phẩm',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.pastelGreenDark),
                        )
                      else
                        const Text(
                          'Hết hàng',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Rating Summary & Sold Count
                  Row(
                    children: [
                      StarRatingBar(
                        rating: widget.product.rating > 0
                            ? widget.product.rating
                            : 5.0,
                        starSize: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.product.rating > 0 ? widget.product.rating.toStringAsFixed(1) : "5.0"} (${reviews.length} đánh giá)',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 16),
                      if (widget.product.sold > 0)
                        Text(
                          'Đã bán ${widget.product.sold}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatPrice(displayPrice),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.pastelPinkDark,
                        ),
                      ),
                      if (widget.product.isOnSale) ...[
                        const SizedBox(width: 10),
                        Text(
                          _formatPrice(widget.product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số lượng',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E2E5)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _quantity < (widget.product.stock > 0 ? widget.product.stock : 99)
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Product Description (HTML format supported)
                  const Text(
                    'Mô tả sản phẩm 📝',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.product.description.contains('<') &&
                      widget.product.description.contains('>'))
                    Html(
                      data: widget.product.description,
                      style: {
                        "body": Style(
                          fontSize: FontSize(14),
                          color: AppColors.ink,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                      },
                    )
                  else
                    Text(
                      widget.product.description.isNotEmpty
                          ? widget.product.description
                          : 'Chưa có mô tả chi tiết cho sản phẩm này.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Review & Rating System ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đánh giá & Nhận xét (${reviews.length}) ⭐',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          if (!auth.isLoggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                            return;
                          }
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddReviewBottomSheet(
                                product: widget.product),
                          );
                        },
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Viết đánh giá'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating Breakdown & Stats
                  if (reviews.isNotEmpty) ...[
                    _buildRatingStats(reviewProvider),
                    const SizedBox(height: 16),
                  ],

                  // Reviews List
                  if (reviewProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.star_outline,
                              size: 36, color: AppColors.pastelPinkDark),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có đánh giá nào',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hãy mua hàng và là người đầu tiên để lại nhận xét nhé!',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...reviews.map((r) => ReviewCard(review: r)),
                  
                  const SizedBox(height: 28),
                  if (similarProducts.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Sản phẩm tương tự 🛍️',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: similarProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final p = similarProducts[index];
                          return SizedBox(
                            width: 160,
                            child: OptimizedProductCard(
                              product: p,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OptimizedProductDetailScreen(
                                      product: p,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Fixed Action Bar ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Column total price
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tạm tính',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    Text(
                      _formatPrice(totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.pastelPinkDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Button Thêm vào giỏ
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed: _addToCart,
                  child: const Text('Thêm vào giỏ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),

              // Button Mua ngay
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _buyNow,
                  child: const Text('Mua ngay',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStats(ReviewProvider provider) {
    final dist = provider.ratingDistribution;
    final total = provider.reviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2EAF0)),
      ),
      child: Row(
        children: [
          // Average Big Rating Score
          Column(
            children: [
              Text(
                provider.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.pastelPinkDark,
                ),
              ),
              StarRatingBar(rating: provider.averageRating, starSize: 14),
              const SizedBox(height: 4),
              Text(
                '$total nhận xét',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Rating Bars (5..1 star)
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star★',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppColors.softPink,
                            color: const Color(0xFFFFB800),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.softPink,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.pastelPinkDark,
          size: 64,
        ),
      ),
    );
  }
}
