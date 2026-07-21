import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/optimized_product_card.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/responsive_frame.dart';
import '../../widgets/product_filter_sheet.dart';
import '../cart/cart_screen.dart';
import 'optimized_product_detail_screen.dart';

class OptimizedProductListScreen extends StatefulWidget {
  const OptimizedProductListScreen({super.key});

  @override
  State<OptimizedProductListScreen> createState() => _OptimizedProductListScreenState();
}

class _OptimizedProductListScreenState extends State<OptimizedProductListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.fetchProducts();
      provider.fetchCategories();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ProductProvider>().setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final filter = productProvider.filter;
    final categories = productProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 10),
            const Text('Tupi House',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng yêu thích đang phát triển')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await productProvider.fetchProducts();
          await productProvider.fetchCategories();
        },
        child: ResponsiveFrame(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.softPink, AppColors.softGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khám phá sản phẩm 🌸',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.pastelPinkDark),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Chọn những món đồ decor xinh xắn cho không gian của bạn ✨',
                      style: TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search & Filter controls
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Button
                  Badge(
                    label: Text('${filter.activeCount}'),
                    isLabelVisible: filter.hasActiveFilters,
                    backgroundColor: AppColors.pastelPinkDark,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: filter.hasActiveFilters
                            ? AppColors.softPink
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: filter.hasActiveFilters
                              ? AppColors.pastelPinkDark
                              : Colors.transparent,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: filter.hasActiveFilters
                              ? AppColors.pastelPinkDark
                              : AppColors.ink,
                        ),
                        onPressed: () {
                          ProductFilterSheet.show(
                            context,
                            currentFilter: filter,
                            categories: categories,
                            currentSort: productProvider.sortOption,
                            onApply: (newFilter) {
                              productProvider.applyFilter(newFilter);
                            },
                            onSortChanged: (newSort) {
                              productProvider.setSortOption(newSort);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal Category Chips
              if (categories.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Tất cả'),
                          selected: filter.categoryId == null,
                          selectedColor: AppColors.softPink,
                          labelStyle: TextStyle(
                            color: filter.categoryId == null
                                ? AppColors.pastelPinkDark
                                : AppColors.ink,
                            fontWeight: filter.categoryId == null
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) => productProvider.applyFilter(
                            filter.copyWith(clearCategory: true),
                          ),
                        ),
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat.name),
                              selected: filter.categoryId == cat.id,
                              selectedColor: AppColors.softPink,
                              labelStyle: TextStyle(
                                color: filter.categoryId == cat.id
                                    ? AppColors.pastelPinkDark
                                    : AppColors.ink,
                                fontWeight: filter.categoryId == cat.id
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (_) => productProvider.applyFilter(
                                filter.copyWith(categoryId: cat.id),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Results counter
              if (filter.hasActiveFilters || productProvider.searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tìm thấy ${productProvider.totalFilteredCount} kết quả',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          productProvider.resetFilters();
                        },
                        child: const Text('Xóa bộ lọc'),
                      ),
                    ],
                  ),
                ),

              // Grid list using new OptimizedProductCard
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (productProvider.isLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Đang tải sản phẩm...',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    if (productProvider.errorMessage != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            productProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final displayed = productProvider.displayedProducts;

                    if (displayed.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted),
                            SizedBox(height: 12),
                            Text('Không tìm thấy sản phẩm nào', style: TextStyle(fontSize: 15, color: AppColors.muted)),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: displayed.length + (productProvider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayed.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final product = displayed[index];
                        return OptimizedProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OptimizedProductDetailScreen(product: product),
                              ),
                            );
                          },
                          isFavorite: false,
                          onToggleFavorite: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng yêu thích đang phát triển')),
                            );
                          },
                          onAddToCart: () {},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
