import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/optimized_product_card.dart';
import '../../widgets/product_filter_sheet.dart';
import '../../widgets/skeleton_product_card.dart';
import '../cart/cart_screen.dart';
import '../login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'optimized_product_detail_screen.dart';
import 'categories_screen.dart';

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

    // 1. Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CategoryProvider>().fetchCategories();
    });

    // 2. Listen for scroll to trigger lazy loading
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= 200) {
      final provider = context.read<ProductProvider>();
      if (provider.hasMore) {
        provider.loadMore();
      }
    }
  }

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

  String _getUserGreeting() {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.currentUser != null) {
      final name = auth.currentUser!.fullName;
      if (name.isNotEmpty) {
        // Get first name
        final firstName = name.split(' ').first;
        return 'Xin chào, $firstName 👋';
      }
      // Try to get from email
      final email = auth.currentUser!.email;
      if (email.isNotEmpty) {
        final emailName = email.split('@').first;
        return 'Xin chào, $emailName 👋';
      }
    }
    return 'Xin chào 👋';
  }

  String _getMainTitle() {
    return 'Khám phá món decor dành riêng cho bạn';
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('búp bê') || name.contains('len') || name.contains('thú bông'))
      return Icons.toys_outlined;
    if (name.contains('hoa') || name.contains('khô'))
      return Icons.local_florist_outlined;
    if (name.contains('móc khóa') || name.contains('keychain'))
      return Icons.key_outlined;
    if (name.contains('nến') || name.contains('thơm'))
      return Icons.local_fire_department_outlined;
    if (name.contains('gương'))
      return Icons.crop_square_outlined;
    if (name.contains('tranh') || name.contains('treo'))
      return Icons.image_outlined;
    if (name.contains('đèn') || name.contains('lamp'))
      return Icons.light_outlined;
    if (name.contains('gốm') || name.contains('sứ') || name.contains('lọ') || name.contains('bình'))
      return Icons.spa_outlined;
    if (name.contains('quà') || name.contains('tặng'))
      return Icons.card_giftcard_outlined;
    if (name.contains('trang trí') || name.contains('decor'))
      return Icons.auto_awesome_outlined;
    if (name.contains('cây') || name.contains('mini'))
      return Icons.eco_outlined;
    if (name.contains('khay') || name.contains('tray'))
      return Icons.dashboard_outlined;
    return Icons.spa_outlined;
  }

  void _viewAllFlashSale() {
    // Filter to show only sale products and scroll to product list
    context.read<ProductProvider>().resetFilters();
    // Show toast or scroll to products
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hiển thị tất cả sản phẩm giảm giá'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final displayedProducts = productProvider.displayedProducts;
    final selectedCatId = productProvider.filterState.categoryId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isSearchOrFilterActive = (selectedCatId != null && selectedCatId.isNotEmpty) ||
        productProvider.searchQuery.isNotEmpty ||
        productProvider.filterState.minPrice > 0 ||
        productProvider.filterState.maxPrice < 2000000 ||
        productProvider.filterState.minRating > 0 ||
        productProvider.filterState.onlyInStock;

    // Responsive grid columns
    int crossAxisCount = 2;
    if (screenWidth >= 768) crossAxisCount = 3;
    if (screenWidth >= 1024) crossAxisCount = 4;
    if (screenWidth >= 1440) crossAxisCount = 5;

    // Get flash sale products - take more if available
    final allProducts = productProvider.filteredProducts;
    final flashSaleProducts = allProducts
        .where((p) => p.isCurrentlyFlashSale || p.isOnSale)
        .toList();
    // If not enough sale products, add popular products
    if (flashSaleProducts.length < 4) {
      final popularIds = flashSaleProducts.map((p) => p.id).toSet();
      for (var product in allProducts) {
        if (!popularIds.contains(product.id) && flashSaleProducts.length < 6) {
          flashSaleProducts.add(product);
        }
      }
    }

    // Get best selling products
    final bestSellingProducts = List<Product>.from(allProducts)
      ..sort((a, b) => b.sold.compareTo(a.sold));
    final displayBestSelling = bestSellingProducts.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar / Header ───────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.warmWhite,
            elevation: 0,
            toolbarHeight: 70,
            titleSpacing: 0,
            title: Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 16 : 24,
                right: isMobile ? 8 : 16,
              ),
              child: Row(
                children: [
                  // Logo and Brand Name
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPinkLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tupi House',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Decor & Handmade',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action Icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer<NotificationProvider>(
                        builder: (context, notif, _) {
                          final count = notif.unreadCount;
                          return _buildActionButton(
                            icon: count > 0
                                ? Icons.notifications_rounded
                                : Icons.notifications_outlined,
                            badge: count,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.favorite_border_rounded,
                        onTap: () {
                          final auth = context.read<AuthProvider>();
                          if (auth.isLoggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WishlistScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.shopping_cart_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Greeting Section ────────────────────────────────────────────────
          if (!isSearchOrFilterActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  8,
                  isMobile ? 16 : 24,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return Text(
                          _getUserGreeting(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getMainTitle(),
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

          // ── Search Bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: Container(
                height: isMobile ? 52 : 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineSoft),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Tìm búp bê len, lọ hoa, nến thơm...',
                          hintStyle: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.muted,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<ProductProvider>()
                              .setSearchQuery('');
                        },
                      ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: Material(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _openFilterSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hero Banner ─────────────────────────────────────────────────────
          if (!isSearchOrFilterActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  24,
                  isMobile ? 16 : 24,
                  0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 400;
                    return _buildHeroBanner(isMobile, isSmall);
                  },
                ),
              ),
            ),

          // ── Quick Category Section ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                28,
                isMobile ? 16 : 24,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh mục',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriesScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Xem tất cả',
                                style: TextStyle(
                                  color: AppColors.primaryPink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primaryPink,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Category Horizontal List ───────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110, // Increased height to prevent overflow
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                children: [
                  _buildQuickCategoryItem(
                    'Tất cả',
                    Icons.grid_view_rounded,
                    selectedCatId == null || selectedCatId.isEmpty,
                    AppColors.primaryPinkLight,
                    () => context
                        .read<ProductProvider>()
                        .setCategoryFilter(null),
                  ),
                  ...categories.map((cat) {
                    final isSelected = selectedCatId == cat.id;
                    return _buildQuickCategoryItem(
                      cat.name,
                      _getCategoryIcon(cat.name),
                      isSelected,
                      isSelected
                          ? AppColors.primaryPinkLight
                          : _getCategoryColor(cat.name),
                      () => context
                          .read<ProductProvider>()
                          .setCategoryFilter(isSelected ? null : cat.id),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Flash Sale Section ──────────────────────────────────────────────
          if (!isSearchOrFilterActive && flashSaleProducts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  32,
                  isMobile ? 16 : 24,
                  16,
                ),
                child: _buildSectionHeader(
                  'Flash Sale',
                  'Ưu đãi nổi bật dành cho bạn',
                  isMobile,
                  showViewAll: true,
                  onViewAll: _viewAllFlashSale,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  itemCount: flashSaleProducts.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < flashSaleProducts.length - 1 ? 12 : 0,
                      ),
                      child: SizedBox(
                        width: isMobile ? 160 : 180,
                        child: OptimizedProductCard(
                          product: flashSaleProducts[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OptimizedProductDetailScreen(
                                  product: flashSaleProducts[index],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // ── Featured Collections ────────────────────────────────────────────
          if (!isSearchOrFilterActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  32,
                  isMobile ? 16 : 24,
                  16,
                ),
                child: _buildFeaturedCollections(isMobile, isTablet),
              ),
            ),

          // ── Best Selling Section ───────────────────────────────────────────
          if (!isSearchOrFilterActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  16,
                  isMobile ? 16 : 24,
                  16,
                ),
                child: _buildSectionHeader(
                  'Được yêu thích nhất',
                  'Những món decor được khách hàng lựa chọn',
                  isMobile,
                ),
              ),
            ),

          // ── Best Selling Products ─────────────────────────────────────────
          if (!isSearchOrFilterActive)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  itemCount: displayBestSelling.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < displayBestSelling.length - 1 ? 12 : 0,
                      ),
                      child: SizedBox(
                        width: isMobile ? 160 : 180,
                        child: OptimizedProductCard(
                          product: displayBestSelling[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OptimizedProductDetailScreen(
                                  product: displayBestSelling[index],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Main Products Section ─────────────────────────────────────────
          if (!isSearchOrFilterActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  32,
                  isMobile ? 16 : 24,
                  16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gợi ý cho bạn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${displayedProducts.length} sản phẩm',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Results Header (Search / Filter) ──────────────────────────────
          if (isSearchOrFilterActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  16,
                  isMobile ? 16 : 24,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb/category label
                    Text(
                      selectedCatId != null && selectedCatId.isNotEmpty
                          ? 'Trang chủ / Danh mục / ${categories.firstWhere((c) => c.id == selectedCatId, orElse: () =>  Category(id: '', name: '', image: '')).name}'
                          : 'Trang chủ / Kết quả tìm kiếm',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Strong title
                    Text(
                      selectedCatId != null && selectedCatId.isNotEmpty
                          ? categories.firstWhere((c) => c.id == selectedCatId, orElse: ()  => Category(id: '', name: 'Mục sản phẩm', image: '')).name
                          : 'Tìm kiếm: "${productProvider.searchQuery}"',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Result count underneath
                    Text(
                      'Đã tìm thấy ${displayedProducts.length} sản phẩm',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sort & Filter buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Bộ lọc & Sắp xếp'),
                            onPressed: _openFilterSheet,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.outlineSoft),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (productProvider.filterState.categoryId != null ||
                            productProvider.searchQuery.isNotEmpty ||
                            productProvider.filterState.minPrice > 0 ||
                            productProvider.filterState.maxPrice < 2000000 ||
                            productProvider.filterState.minRating > 0 ||
                            productProvider.filterState.onlyInStock) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            color: AppColors.primaryPink,
                            tooltip: 'Thiết lập lại',
                            onPressed: () {
                              _searchController.clear();
                              productProvider.resetFilters();
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Product Grid ───────────────────────────────────────────────────
          if (productProvider.isLoading)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const SkeletonProductCard(),
                  childCount: crossAxisCount * 2,
                ),
              ),
            )
          else if (displayedProducts.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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

          // ── Lazy Loading Indicator ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: 24,
                bottom: bottomPadding + 80, // Extra padding for bottom nav
              ),
              child: Center(
                child: productProvider.hasMore
                    ? Column(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryPink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Đang tải thêm...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      )
                    : displayedProducts.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Đã hiển thị ${displayedProducts.length} sản phẩm',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoftPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 22,
                color: AppColors.textPrimary,
              ),
              if (badge > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.saleRedPink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
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

  Widget _buildHeroBanner(bool isMobile, bool isSmall) {
    final titleSize = isMobile ? (isSmall ? 18.0 : 22.0) : 28.0;
    final subtitleSize = isMobile ? 12.0 : 14.0;
    final buttonPaddingH = isMobile ? 16.0 : 24.0;
    final buttonPaddingV = isMobile ? 10.0 : 12.0;

    return Container(
      constraints: BoxConstraints(
        minHeight: isMobile ? 160 : 200,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lightBlush,
            AppColors.lightCream,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPinkLight.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sageGreen.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Content - using Wrap for responsive layout
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Wrap(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Bộ sưu tập mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 10 : 12),
                    SizedBox(
                      width: isMobile ? null : 200,
                      child: Text(
                        'Decor dễ thương\ncho góc nhỏ của bạn',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    SizedBox(
                      width: isMobile ? null : 220,
                      child: Text(
                        'Khám phá bộ sưu tập handmade mới với ưu đãi đến 30%',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: buttonPaddingH,
                            vertical: buttonPaddingV,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Khám phá ngay',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategoryItem(
    String label,
    IconData icon,
    bool isSelected,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 88, // Slightly wider
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? bgColor : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primaryPink : AppColors.outlineSoft,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPink.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryPink
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryPink
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('búp bê') || name.contains('len'))
      return const Color(0xFFFFE4EC);
    if (name.contains('hoa') || name.contains('khô'))
      return const Color(0xFFE8F5E9);
    if (name.contains('nến') || name.contains('thơm'))
      return const Color(0xFFFFF3E0);
    if (name.contains('gương'))
      return const Color(0xFFE3F2FD);
    if (name.contains('tranh') || name.contains('treo'))
      return const Color(0xFFFCE4EC);
    if (name.contains('đèn'))
      return const Color(0xFFFFF8E1);
    if (name.contains('gốm') || name.contains('sứ'))
      return const Color(0xFFF5F5DC);
    if (name.contains('quà') || name.contains('tặng'))
      return const Color(0xFFF3E5F5);
    return const Color(0xFFFAFAFA);
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    bool isMobile, {
    bool showViewAll = false,
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (title == 'Flash Sale')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: AppColors.saleRedPink,
                      size: 22,
                    ),
                  ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (showViewAll)
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryPink,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedCollections(bool isMobile, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildCollectionCard(
            'Góc phòng\nngọt ngào',
            'Handmade đáng yêu',
            AppColors.lightBlush,
            Icons.home_outlined,
            isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: _buildCollectionCard(
            'Quà tặng\nxin xắn',
            'Cho người thương',
            AppColors.lightCream,
            Icons.card_giftcard_outlined,
            isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(
    String title,
    String subtitle,
    Color bgColor,
    IconData icon,
    bool isMobile,
  ) {
    return Container(
      height: isMobile ? 120 : 140,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.primaryPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primaryPinkLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 56,
                color: AppColors.primaryPink,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa tìm thấy món decor phù hợp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                context.read<ProductProvider>().resetFilters();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryPink,
                side: const BorderSide(color: AppColors.primaryPink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }
}
