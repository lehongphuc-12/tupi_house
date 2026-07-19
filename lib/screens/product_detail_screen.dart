import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/product_image.dart';
import '../widgets/product_card.dart';
import '../models/cart.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
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
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: products[index])));
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

  Widget _buildReviews() {
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
              TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
            ],
          ),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: 3,
          separatorBuilder: (_, __) => const Divider(height: 32, color: Color(0xFFF0E8EB)),
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.softPink,
                      child: Text('K${index + 1}', style: const TextStyle(color: AppColors.pastelPinkDark, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Khách hàng ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Row(
                          children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < 4 ? Colors.amber : Colors.grey[300])),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text('${index + 2} ngày trước', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sản phẩm rất xinh và giống hình, gói hàng cẩn thận. Mình rất hài lòng nha shop! 💖',
                  style: TextStyle(height: 1.4, fontSize: 14.5),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoSection(bool isWide) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isWide ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: isWide ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))] : null,
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
                    Text(
                      formatVnd(_product.price.toDouble()),
                      style: const TextStyle(fontSize: 24, color: AppColors.pastelPinkDark, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          SizedBox(width: 4),
                          Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                          SizedBox(width: 4),
                          Text('(120)', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
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
          _buildReviews(),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F9), // Light background to contrast with the card
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
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
              backgroundColor: Colors.white.withOpacity(0.9),
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
            child: ProductImage(path: _product.thumbnail, iconSize: 80),
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
                color: Colors.black.withOpacity(0.04),
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
                      formatVnd(_product.price.toDouble() * _quantity),
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
    );
  }
}
