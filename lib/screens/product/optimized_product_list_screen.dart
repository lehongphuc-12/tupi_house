import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/optimized_product_card.dart';
import '../../widgets/product_filter_sheet.dart';
import '../cart/cart_screen.dart';
import '../login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'optimized_product_detail_screen.dart';

class OptimizedProductListScreen extends StatefulWidget {
  const OptimizedProductListScreen({super.key});

  @override
  State<OptimizedProductListScreen> createState() =>
      _OptimizedProductListScreenState();
}

class _OptimizedProductListScreenState
    extends State<OptimizedProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // 1. Tải dữ liệu ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CategoryProvider>().fetchCategories();
    });

    // 2. Lắng nghe cuộn để kích hoạt Lazy Loading (Phân trang 4 sản phẩm)
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Khi người dùng cuộn tới vị trí cách đáy 200px
    if (maxScroll - currentScroll <= 200) {
      final provider = context.read<ProductProvider>();
      if (provider.hasMore) {
        provider.loadMore();
      }
    }
  }

  // 3. Tìm kiếm có Debounce 300ms
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ProductProvider>().setSearchQuery(query);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProductFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final displayedProducts = productProvider.displayedProducts;
    final selectedCatId = productProvider.filterState.categoryId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'Tupi House',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              final count = notif.unreadCount;
              return IconButton(
                tooltip: 'Thông báo',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: AppColors.pastelPinkDark,
                  child: Icon(
                    count > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (auth.isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ProductProvider>().fetchProducts();
          if (context.mounted) {
            await context.read<CategoryProvider>().fetchCategories();
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Search Bar & Header Section ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Khám phá Tulip Decor 🌸',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mang không gian ấm áp, tinh tế vào ngôi nhà của bạn ✨',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),

                    
                    // Search & Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên hoặc loại sản phẩm...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        context
                                            .read<ProductProvider>()
                                            .setSearchQuery('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _openFilterSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.softPink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.pastelPinkDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category Chips (Horizontal Scrollable)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả'),
                            selected: selectedCatId == null ||
                                selectedCatId.isEmpty,
                            selectedColor: AppColors.softPink,
                            labelStyle: TextStyle(
                              color: selectedCatId == null ||
                                      selectedCatId.isEmpty
                                  ? AppColors.pastelPinkDark
                                  : AppColors.ink,
                              fontWeight: selectedCatId == null ||
                                      selectedCatId.isEmpty
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            onSelected: (_) {
                              context
                                  .read<ProductProvider>()
                                  .setCategoryFilter(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...categories.map((cat) {
                            final isSelected = selectedCatId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                selectedColor: AppColors.softPink,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.pastelPinkDark
                                      : AppColors.ink,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                onSelected: (selected) {
                                  context
                                      .read<ProductProvider>()
                                      .setCategoryFilter(
                                          selected ? cat.id : null);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Grid Product List ────────────────────────────────────────────
            if (productProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (displayedProducts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.softPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.pastelPinkDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không tìm thấy sản phẩm phù hợp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductProvider>().resetFilters();
                        },
                        child: const Text('Bỏ bộ lọc'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = displayedProducts[index];
                      return OptimizedProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OptimizedProductDetailScreen(
                                product: product,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: displayedProducts.length,
                  ),
                ),
              ),

            // ── Lazy Loading Indicator / End of List Banner ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: productProvider.hasMore
                      ? const Column(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.pastelPinkDark,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Đang tải thêm sản phẩm...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          displayedProducts.isNotEmpty
                              ? '🌱 Đã hiển thị tất cả ${displayedProducts.length} sản phẩm'
                              : '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
