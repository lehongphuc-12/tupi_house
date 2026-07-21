import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/responsive_frame.dart';
import 'product_detail_screen.dart';
import 'cart/cart_screen.dart'; 

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

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
            onPressed: () {}, // Không làm gì
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
        onRefresh: () => context.read<ProductProvider>().fetchProducts(),
        child: ResponsiveFrame(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Khám phá sản phẩm 🌸',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.pastelPinkDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn những món đồ decor xinh xắn cho không gian của bạn ✨',
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ProductProvider>().setSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) =>
                    context.read<ProductProvider>().setSearchQuery(value),
              ),
              const SizedBox(height: 16),

              // Sort Options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Sắp xếp:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Mặc định'),
                      selected: productProvider.sortOption == SortOption.none,
                      onSelected: (_) => context
                          .read<ProductProvider>()
                          .setSortOption(SortOption.none),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Giá tăng dần'),
                      selected:
                          productProvider.sortOption == SortOption.priceAsc,
                      onSelected: (_) => context
                          .read<ProductProvider>()
                          .setSortOption(SortOption.priceAsc),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Giá giảm dần'),
                      selected:
                          productProvider.sortOption == SortOption.priceDesc,
                      onSelected: (_) => context
                          .read<ProductProvider>()
                          .setSortOption(SortOption.priceDesc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Danh sách sản phẩm
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

                    final products = productProvider.products;

                    if (products.isEmpty) {
                      return const Center(
                        child: Text('Không tìm thấy sản phẩm nào',
                            style: TextStyle(fontSize: 16)),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65, // Tăng tỷ lệ để card đủ không gian, tránh overflow
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            isFavorite: false,
                            onToggleFavorite: () {},
                            onAddToCart: () {},
                          );
                        },
                      ),
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
