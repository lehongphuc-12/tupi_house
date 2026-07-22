import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedItems = {};

  bool get _isAllSelected {
    final cart = context.read<CartProvider>().cart;
    return _selectedItems.length == cart.items.length && cart.items.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cart = cartProvider.cart;

    // Tính tổng tiền của các sản phẩm đã chọn
    final selectedTotal = cart.items
        .where((item) => _selectedItems.contains(item.productId))
        .fold(0, (sum, item) => sum + (item.price * item.quantity));

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedItems.isEmpty
            ? "Giỏ hàng của bạn"
            : "${_selectedItems.length} đã chọn"),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSelectedItems(cartProvider),
            ),
          //   IconButton(
          //     icon: const Icon(Icons.delete_outline),
          //     onPressed: cart.items.isEmpty ? null : () => _showClearDialog(context, cartProvider),
          //   ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // Header chọn tất cả
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAllSelected,
                        onChanged: (value) => _toggleSelectAll(cart),
                      ),
                      const Text("Chọn tất cả", style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      if (_selectedItems.isNotEmpty)
                        Text(
                          "Đã chọn: ${formatVnd(selectedTotal.toDouble())}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItem(item, cartProvider);
                    },
                  ),
                ),

                _buildOrderSummary(cart, selectedTotal),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    final isSelected = _selectedItems.contains(item.productId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedItems.add(item.productId);
                  } else {
                    _selectedItems.remove(item.productId);
                  }
                });
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.thumbnail,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 75),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.color != null || item.size != null)
                    Text(
                      "${item.color != null ? 'Màu: ${item.color}' : ''} ${item.size != null ? '| Size: ${item.size}' : ''}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    formatVnd(item.price.toDouble()),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.pastelPinkDark),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () async {
                        try {
                          await cartProvider.updateQuantity(
                              item.productId, item.quantity - 1);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceAll('Exception: ', ''))));
                          }
                        }
                      },
                    ),
                    Text("${item.quantity}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () async {
                        try {
                          await cartProvider.updateQuantity(
                              item.productId, item.quantity + 1);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceAll('Exception: ', ''))));
                          }
                        }
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await cartProvider.removeItem(item.productId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Đã xóa sản phẩm khỏi giỏ hàng")));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                e.toString().replaceAll('Exception: ', ''))));
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Cart cart, int selectedTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng thanh toán:", style: TextStyle(fontSize: 18)),
              Text(
                formatVnd(selectedTotal.toDouble()),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pastelPinkDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelPinkDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            selectedItems: cart.items
                                .where((item) =>
                                    _selectedItems.contains(item.productId))
                                .toList(),
                          ),
                        ),
                      );
                    },
              child: const Text(
                "TIẾN HÀNH THANH TOÁN",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Giỏ hàng trống",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Hãy thêm một số sản phẩm yêu thích của bạn"),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quay lại mua sắm"),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll(Cart cart) {
    setState(() {
      if (_isAllSelected) {
        _selectedItems.clear();
      } else {
        _selectedItems.addAll(cart.items.map((item) => item.productId));
      }
    });
  }

  void _deleteSelectedItems(CartProvider cartProvider) async {
    try {
      for (String productId in List.from(_selectedItems)) {
        await cartProvider.removeItem(productId);
      }
      _selectedItems.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa các sản phẩm đã chọn")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showClearDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa giỏ hàng"),
        content: const Text("Bạn có chắc muốn xóa toàn bộ giỏ hàng không?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              _selectedItems.clear();
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
