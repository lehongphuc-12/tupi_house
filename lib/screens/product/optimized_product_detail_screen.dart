import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/cart.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/optimized_product_card.dart';
import '../../widgets/review_card.dart';
import '../../widgets/star_rating_bar.dart';
import '../../widgets/flash_sale_timer_widget.dart';
import '../cart/cart_screen.dart';
import '../login_screen.dart';
import '../checkout_screen.dart';
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
  bool _isDescriptionExpanded = false;
  bool _isAddingToCart = false;

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

  int get _currentPrice {
    if (widget.product.isCurrentlyFlashSale &&
        widget.product.flashSalePrice != null) {
      return widget.product.flashSalePrice!;
    }
    return widget.product.salePrice ?? widget.product.price;
  }

  Future<bool> _ensureLoggedIn() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) return true;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(returnToPrevious: true),
      ),
    );
    if (!mounted) return false;
    return context.read<AuthProvider>().isLoggedIn;
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart || widget.product.stock <= 0) {
      if (widget.product.stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sản phẩm hiện đã hết hàng.')),
        );
      }
      return;
    }

    if (!await _ensureLoggedIn() || !mounted) return;

    setState(() => _isAddingToCart = true);
    try {
      final cartItem = CartItem(
        productId: widget.product.id,
        title: widget.product.title,
        price: _currentPrice,
        thumbnail: widget.product.thumbnail,
        quantity: _quantity,
      );
      await context.read<CartProvider>().addToCart(cartItem);
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                Expanded(
                  child: Text(
                    'Đã thêm $_quantity sản phẩm vào giỏ hàng.',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  child: const Text(
                    'Xem giỏ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thêm sản phẩm vào giỏ. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _buyNow() async {
    if (widget.product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm hiện đã hết hàng.')),
      );
      return;
    }
    if (!await _ensureLoggedIn() || !mounted) return;

    final cartItem = CartItem(
      productId: widget.product.id,
      title: widget.product.title,
      price: _currentPrice,
      thumbnail: widget.product.thumbnail,
      quantity: _quantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(selectedItems: [cartItem]),
      ),
    );
  }

  Future<void> _toggleWishlist(WishlistProvider wishlist) async {
    if (!await _ensureLoggedIn() || !mounted) return;
    try {
      await wishlist.toggleWishlist(widget.product);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật danh sách yêu thích.'),
        ),
      );
    }
  }

  Future<void> _openReviewSheet() async {
    if (!await _ensureLoggedIn() || !mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReviewBottomSheet(product: widget.product),
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

    final isFlashSale = widget.product.isCurrentlyFlashSale;
    final displayPrice = isFlashSale
        ? widget.product.flashSalePrice!
        : (widget.product.salePrice ?? widget.product.price);
    final totalAmount = displayPrice * _quantity;

    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.thumbnail];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (!isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: _buildDesktopLayout(
          context: context,
          images: images,
          isFavorite: isFavorite,
          wishlist: wishlist,
          reviewProvider: reviewProvider,
          reviews: reviews,
          similarProducts: similarProducts,
          isFlashSale: isFlashSale,
          displayPrice: displayPrice,
          totalAmount: totalAmount,
        ),
      );
    }

    return _buildMobileLayout(
      context: context,
      images: images,
      isFavorite: isFavorite,
      wishlist: wishlist,
      reviewProvider: reviewProvider,
      reviews: reviews,
      similarProducts: similarProducts,
      isFlashSale: isFlashSale,
      displayPrice: displayPrice,
      totalAmount: totalAmount,
      isMobile: isMobile,
    );
  }

  Widget _buildDesktopLayout({
    required BuildContext context,
    required List<String> images,
    required bool isFavorite,
    required WishlistProvider wishlist,
    required ReviewProvider reviewProvider,
    required List<Review> reviews,
    required List<Product> similarProducts,
    required bool isFlashSale,
    required int displayPrice,
    required int totalAmount,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildDesktopGallery(images),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: _buildDesktopProductPanel(
                      context: context,
                      isFavorite: isFavorite,
                      wishlist: wishlist,
                      reviews: reviews,
                      isFlashSale: isFlashSale,
                      displayPrice: displayPrice,
                      totalAmount: totalAmount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildDesktopReviews(
                context: context,
                reviewProvider: reviewProvider,
                reviews: reviews,
              ),
              if (similarProducts.isNotEmpty) ...[
                const SizedBox(height: 40),
                const Text(
                  'Có thể bạn cũng thích',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: similarProducts.length > 5 ? 5 : similarProducts.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final product = similarProducts[index];
                    return OptimizedProductCard(
                      product: product,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OptimizedProductDetailScreen(
                            product: product,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGallery(List<String> images) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.04,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              color: AppColors.lightCream,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  final image = images[index];
                  return Hero(
                    tag: index == 0
                        ? 'product-img-${widget.product.id}'
                        : 'product-img-${widget.product.id}-$index',
                    child: Material(
                      type: MaterialType.transparency,
                      child: image.isEmpty
                          ? _imagePlaceholder()
                          : Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == _currentImageIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 82,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryPink
                            : AppColors.outlineSoft,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: images[index].isEmpty
                          ? _imagePlaceholder()
                          : Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopProductPanel({
    required BuildContext context,
    required bool isFavorite,
    required WishlistProvider wishlist,
    required List<Review> reviews,
    required bool isFlashSale,
    required int displayPrice,
    required int totalAmount,
  }) {
    final inStock = widget.product.stock > 0;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFlashSale && widget.product.flashSaleEndTime != null) ...[
            FlashSaleTimerWidget(
              endTime: widget.product.flashSaleEndTime!,
            ),
            const SizedBox(height: 18),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isFlashSale || widget.product.isOnSale)
                _detailChip(
                  isFlashSale ? '⚡ FLASH SALE' : 'SALE',
                  AppColors.saleRedPink,
                  Colors.white,
                ),
              _detailChip(
                widget.product.categoryName.isNotEmpty
                    ? widget.product.categoryName
                    : 'Decor',
                AppColors.softPink,
                AppColors.primaryPinkDark,
              ),
              _detailChip(
                inStock ? 'Còn ${widget.product.stock} sản phẩm' : 'Hết hàng',
                inStock ? AppColors.softGreen : AppColors.errorLight,
                inStock ? AppColors.deepSage : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.product.title,
            style: const TextStyle(
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.product.rating > 0) ...[
                StarRatingBar(rating: widget.product.rating, starSize: 18),
                Text(
                  '${widget.product.rating.toStringAsFixed(1)} '
                  '(${reviews.length} đánh giá)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkLight,
                  ),
                ),
              ] else
                const Text(
                  'Chưa có đánh giá',
                  style: TextStyle(color: AppColors.muted),
                ),
              if (widget.product.sold > 0)
                Text(
                  'Đã bán ${widget.product.sold}',
                  style: const TextStyle(color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _formatPrice(displayPrice),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryPinkDark,
                ),
              ),
              if (isFlashSale || widget.product.isOnSale)
                Text(
                  _formatPrice(widget.product.price),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.lightCream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mô tả sản phẩm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDescription(expanded: true),
                if (widget.product.metaInfo.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildMetaInfo(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số lượng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildQuantityStepper(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Tạm tính',
                style: TextStyle(color: AppColors.muted),
              ),
              const Spacer(),
              Text(
                _formatPrice(totalAmount),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.woodBrownDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Tooltip(
                message: isFavorite
                    ? 'Bỏ khỏi yêu thích'
                    : 'Thêm vào yêu thích',
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _toggleWishlist(wishlist),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.primaryPink,
                      side: const BorderSide(color: AppColors.outlineSoft),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: inStock && !_isAddingToCart ? _addToCart : null,
                  icon: _isAddingToCart
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    _isAddingToCart ? 'Đang thêm...' : 'Thêm vào giỏ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: inStock ? _buyNow : null,
              icon: const Icon(Icons.flash_on_rounded),
              label: Text(inStock ? 'Mua ngay' : 'Tạm hết hàng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopReviews({
    required BuildContext context,
    required ReviewProvider reviewProvider,
    required List<Review> reviews,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đánh giá & nhận xét (${reviews.length})',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openReviewSheet,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Viết đánh giá'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (reviewProvider.errorMessage != null)
            _messagePanel(
              icon: Icons.error_outline_rounded,
              message: 'Không thể tải nhận xét. Vui lòng thử lại.',
              actionLabel: 'Tải lại',
              onPressed: () => reviewProvider.loadReviews(widget.product.id),
            )
          else if (reviewProvider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (reviews.isEmpty)
            _messagePanel(
              icon: Icons.rate_review_outlined,
              message: 'Chưa có đánh giá nào. Hãy chia sẻ cảm nhận đầu tiên.',
              actionLabel: 'Viết đánh giá',
              onPressed: _openReviewSheet,
            )
          else ...[
            _buildRatingStats(reviewProvider),
            const SizedBox(height: 20),
            ...reviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReviewCard(review: review),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailChip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDescription({required bool expanded}) {
    final description = widget.product.description;
    final empty = description.trim().isEmpty;
    final content = empty
        ? 'Chưa có mô tả chi tiết cho sản phẩm này.'
        : description;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: expanded ? double.infinity : 150),
      child: ClipRect(
        child: content.contains('<') && content.contains('>')
            ? Html(
                data: content,
                style: {
                  'body': Style(
                    fontSize: FontSize(14),
                    color: AppColors.ink,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
              )
            : Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.ink,
                  height: 1.55,
                ),
              ),
      ),
    );
  }

  Widget _buildMetaInfo() {
    final entries = widget.product.metaInfo.entries
        .where((entry) => entry.value != null && entry.value.toString().trim().isNotEmpty)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantityStepper() {
    final maxQuantity = widget.product.stock > 0 ? widget.product.stock : 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 44,
            child: IconButton(
              tooltip: 'Giảm số lượng',
              icon: const Icon(Icons.remove, size: 18),
              onPressed: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox.square(
            dimension: 44,
            child: IconButton(
              tooltip: 'Tăng số lượng',
              icon: const Icon(Icons.add, size: 18),
              onPressed: _quantity < maxQuantity
                  ? () => setState(() => _quantity++)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagePanel({
    required IconData icon,
    required String message,
    String? actionLabel,
    Future<void> Function()? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.lightCream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.primaryPink),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLayout({
    required BuildContext context,
    required List<String> images,
    required bool isFavorite,
    required WishlistProvider wishlist,
    required ReviewProvider reviewProvider,
    required List<Review> reviews,
    required List<Product> similarProducts,
    required bool isFlashSale,
    required int displayPrice,
    required int totalAmount,
    required bool isMobile,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
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
                        child: Material(
                          type: MaterialType.transparency,
                          child: images[index].isNotEmpty
                              ? Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(),
                                )
                              : _imagePlaceholder(),
                        ),
                      );
                    },
                  ),

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
                  icon: const Icon(Icons.share_outlined, color: AppColors.ink),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng chia sẻ đang phát triển')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.primaryPink : AppColors.ink,
                  ),
                  onPressed: () => _toggleWishlist(wishlist),
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
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFlashSale && widget.product.flashSaleEndTime != null) ...[
                    FlashSaleTimerWidget(endTime: widget.product.flashSaleEndTime!),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      if (isFlashSale)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.saleRedPink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '⚡ FLASH SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      else if (widget.product.isOnSale)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.saleRedPink,
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
                          style: TextStyle(fontSize: 12, color: AppColors.error),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (widget.product.rating > 0) ...[
                        StarRatingBar(
                          rating: widget.product.rating,
                          starSize: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.product.rating.toStringAsFixed(1)} (${reviews.length} đánh giá)',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 16),
                      ] else ...[
                        const Text(
                          'Chưa có đánh giá',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (widget.product.sold > 0)
                        Text(
                          'Đã bán ${widget.product.sold}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                      if (isFlashSale || widget.product.isOnSale) ...[
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số lượng',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      _buildQuantityStepper(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả sản phẩm 📝',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.topCenter,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: _isDescriptionExpanded ? double.infinity : 150,
                      ),
                      child: _buildDescription(
                        expanded: _isDescriptionExpanded,
                      ),
                    ),
                  ),
                  if (widget.product.description.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        icon: Icon(
                          _isDescriptionExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                        ),
                        label: Text(_isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm'),
                      ),
                    ),
                  if (widget.product.metaInfo.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildMetaInfo(),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 16),
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
                        onPressed: _openReviewSheet,
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Viết đánh giá'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (reviews.isNotEmpty) ...[
                    _buildRatingStats(reviewProvider),
                    const SizedBox(height: 16),
                  ],
                  if (reviewProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineSoft),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 40, color: AppColors.muted),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có lượt đánh giá nào',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return ReviewCard(review: reviews[index]);
                      },
                    ),
                  if (similarProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Text(
                      'Sản phẩm tương tự 🌸',
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
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
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed: widget.product.stock > 0 && !_isAddingToCart
                      ? _addToCart
                      : null,
                  child: _isAddingToCart
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Thêm vào giỏ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: widget.product.stock > 0 ? _buyNow : null,
                  child: Text(
                    widget.product.stock > 0 ? 'Mua ngay' : 'Hết hàng',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
        border: Border.all(color: AppColors.outlineSoft),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.lightCream, AppColors.softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_florist_outlined,
          color: AppColors.primaryPink,
          size: 56,
        ),
      ),
    );
  }
}
