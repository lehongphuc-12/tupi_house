import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cart.dart';
import '../../models/product.dart';
import '../../models/wishlist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_image.dart';
import '../login_screen.dart';
import '../main_screen.dart';
import '../product/optimized_product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key, this.onExploreHome});

  final VoidCallback? onExploreHome;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Set<String> _busyProductIds = <String>{};
  final NumberFormat _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  Future<Product?> _loadProduct(String productId) async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Product.fromJson(data);
  }

  Future<void> _navigateToDetail(WishlistItem item) async {
    setState(() => _busyProductIds.add(item.productId));
    try {
      final product = await _loadProduct(item.productId);
      if (!mounted) return;
      if (product == null) {
        _showMessage('Không tìm thấy thông tin sản phẩm.');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OptimizedProductDetailScreen(product: product),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể tải sản phẩm. Vui lòng thử lại.', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyProductIds.remove(item.productId));
      }
    }
  }

  Future<void> _addToCart(WishlistItem item) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(returnToPrevious: true),
        ),
      );
      if (!mounted || !context.read<AuthProvider>().isLoggedIn) return;
    }

    setState(() => _busyProductIds.add(item.productId));
    try {
      final product = await _loadProduct(item.productId);
      if (!mounted) return;
      if (product == null) {
        _showMessage('Sản phẩm không còn tồn tại.', error: true);
        return;
      }
      if (product.stock <= 0) {
        _showMessage('Sản phẩm hiện đã hết hàng.');
        return;
      }

      final price = product.isCurrentlyFlashSale
          ? product.flashSalePrice!
          : (product.salePrice ?? product.price);
      await context.read<CartProvider>().addToCart(
            CartItem(
              productId: product.id,
              title: product.title,
              price: price,
              thumbnail: product.thumbnail,
              quantity: 1,
            ),
          );
      if (mounted) _showMessage('Đã thêm sản phẩm vào giỏ hàng.');
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể thêm vào giỏ hàng. Vui lòng thử lại.',
            error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyProductIds.remove(item.productId));
      }
    }
  }

  Future<void> _removeItem(WishlistItem item) async {
    setState(() => _busyProductIds.add(item.productId));
    try {
      await context.read<WishlistProvider>().toggleWishlist(
            Product(
              id: item.productId,
              title: item.title,
              price: item.price,
              thumbnail: item.thumbnail,
              images: item.thumbnail.isEmpty ? const [] : [item.thumbnail],
              description: '',
              categoryId: '',
              categoryName: item.categoryName,
            ),
          );
      if (mounted) _showMessage('Đã xóa khỏi danh sách yêu thích.');
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể cập nhật danh sách yêu thích.', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyProductIds.remove(item.productId));
      }
    }
  }

  void _goHome() {
    final navigator = Navigator.of(context);
    final callback = widget.onExploreHome;
    if (callback != null) {
      navigator.popUntil((route) => route.isFirst);
      callback();
      return;
    }
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? AppColors.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WishlistProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: const Text('Sản phẩm yêu thích'),
        actions: [
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.softPink,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            );
          }

          if (provider.errorMessage != null && items.isEmpty) {
            return _WishlistMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Chưa thể tải sản phẩm yêu thích',
              description: 'Không thể tải danh sách yêu thích. Vui lòng thử lại sau.',
            );
          }

          if (items.isEmpty) {
            return _WishlistEmptyState(onExplore: _goHome);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final sidePadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            sidePadding,
                            18,
                            sidePadding,
                            16,
                          ),
                          child: Text(
                            'Bạn đang lưu ${items.length} sản phẩm để xem lại sau.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          0,
                          sidePadding,
                          32,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisExtent: 365,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 18,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = items[index];
                              return _WishlistProductCard(
                                item: item,
                                price: _money.format(item.price),
                                busy: _busyProductIds.contains(item.productId),
                                onOpen: () => _navigateToDetail(item),
                                onRemove: () => _removeItem(item),
                                onAddToCart: () => _addToCart(item),
                              );
                            },
                            childCount: items.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WishlistProductCard extends StatelessWidget {
  final WishlistItem item;
  final String price;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const _WishlistProductCard({
    required this.item,
    required this.price,
    required this.busy,
    required this.onOpen,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineSoft),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InkWell(
                    onTap: busy ? null : onOpen,
                    child: ProductImage(path: item.thumbnail),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Xóa khỏi yêu thích',
                        onPressed: busy ? null : onRemove,
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  ),
                  if (busy)
                    const ColoredBox(
                      color: Color(0x3DFFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPink,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.categoryName.trim().isNotEmpty)
                    Text(
                      item.categoryName.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.sageGreenDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: busy ? null : onOpen,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.woodBrownDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: busy ? null : onAddToCart,
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 19),
                      label: const Text('Thêm vào giỏ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistEmptyState extends StatelessWidget {
  final VoidCallback onExplore;

  const _WishlistEmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.softPink, AppColors.lightCream],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 58,
                      color: AppColors.primaryPink,
                    ),
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 23,
                        color: AppColors.warning,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 23,
                      child: Icon(
                        Icons.local_florist_outlined,
                        size: 25,
                        color: AppColors.sageGreenDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Danh sách yêu thích đang trống',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hãy lưu lại những món decor bạn yêu thích để dễ dàng tìm lại sau nhé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: FilledButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Khám phá ngay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _WishlistMessage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.muted),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
