import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;

  const CheckoutScreen({super.key, required this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'cod'; // cod, bank, momo, vnpay
  final TextEditingController _noteController = TextEditingController();

  // Địa chỉ giao hàng mẫu (sau này lấy từ user profile)
  Map<String, dynamic> _shippingAddress = {
    'fullName': 'Nguyễn Văn A',
    'phone': '0123456789',
    'address': '123 Đường ABC, Phường XYZ',
    'ward': 'Phường 1',
    'district': 'Quận 1',
    'city': 'TP. Hồ Chí Minh',
  };

  int get _totalAmount => widget.selectedItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        backgroundColor: AppColors.pastelPinkDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Địa chỉ giao hàng
            _buildShippingAddress(),

            const Divider(height: 8),

            // 2. Danh sách sản phẩm
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Sản phẩm (${widget.selectedItems.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildSelectedProducts(),

            const Divider(height: 8),

            // 3. Phương thức thanh toán
            _buildPaymentMethod(),

            // 4. Ghi chú
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ghi chú cho người bán", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Ví dụ: Gọi trước khi giao hàng...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Chi tiết thanh toán
            _buildPaymentDetails(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildShippingAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.pastelPinkDark),
              const SizedBox(width: 8),
              const Text("Địa chỉ giao hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              TextButton(
                onPressed: _showEditAddressDialog, 
                child: const Text("Thay đổi")
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_shippingAddress['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_shippingAddress['phone'] ?? ''),
          const SizedBox(height: 4),
          Text(_shippingAddress['address'] ?? ''),
          Text("${_shippingAddress['ward']}, ${_shippingAddress['district']}, ${_shippingAddress['city']}"),
        ],
      ),
    );
  }

  void _showEditAddressDialog() {
    final nameController = TextEditingController(text: _shippingAddress['fullName']);
    final phoneController = TextEditingController(text: _shippingAddress['phone']);
    final addressController = TextEditingController(text: _shippingAddress['address']);
    final wardController = TextEditingController(text: _shippingAddress['ward']);
    final districtController = TextEditingController(text: _shippingAddress['district']);
    final cityController = TextEditingController(text: _shippingAddress['city']);

    showDialog(
      context: context,
      builder: (context) {
        // Styling chung cho input để tái sử dụng ngắn gọn
        InputDecoration inputStyle(String label, [IconData? icon]) => InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        );

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Icon(Icons.location_on_rounded, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Thay đổi địa chỉ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                TextField(controller: nameController, textInputAction: TextInputAction.next, decoration: inputStyle('Họ và tên', Icons.person_outline)),
                const SizedBox(height: 10),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: inputStyle('Số điện thoại', Icons.phone_outlined)),
                const SizedBox(height: 10),
                TextField(controller: addressController, textInputAction: TextInputAction.next, decoration: inputStyle('Địa chỉ (Số nhà, đường)', Icons.home_outlined)),
                const SizedBox(height: 10),
                TextField(controller: cityController, textInputAction: TextInputAction.next, decoration: inputStyle('Tỉnh/Thành phố', Icons.location_city_outlined)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: districtController, textInputAction: TextInputAction.next, decoration: inputStyle('Quận/Huyện'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: wardController, textInputAction: TextInputAction.done, decoration: inputStyle('Phường/Xã'))),
                  ],
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _shippingAddress = {
                          'fullName': nameController.text,
                          'phone': phoneController.text,
                          'address': addressController.text,
                          'ward': wardController.text,
                          'district': districtController.text,
                          'city': cityController.text,
                        };
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedProducts() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.selectedItems.length,
      itemBuilder: (context, index) {
        final item = widget.selectedItems[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item.thumbnail, width: 60, height: 60, fit: BoxFit.cover),
          ),
          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            "${item.color != null ? 'Màu: ${item.color} ' : ''}${item.size != null ? 'Size: ${item.size}' : ''}",
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatVnd(item.price.toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("x${item.quantity}"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Phương thức thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _paymentOption("Thanh toán khi nhận hàng (COD)", "cod", Icons.delivery_dining),
          _paymentOption("Chuyển khoản ngân hàng", "bank", Icons.account_balance),
          _paymentOption("Ví MoMo", "momo", Icons.wallet),
          _paymentOption("ZaloPay / VNPay", "vnpay", Icons.payment),
        ],
      ),
    );
  }

  Widget _paymentOption(String title, String method, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.pastelPinkDark),
      title: Text(title),
      trailing: Radio<String>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
      ),
      onTap: () => setState(() => _selectedPaymentMethod = method),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Chi tiết thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _detailRow("Tổng tiền hàng", formatVnd(_totalAmount.toDouble())),
          _detailRow("Phí vận chuyển", "30.000đ"),
          const Divider(),
          _detailRow("Tổng thanh toán", formatVnd((_totalAmount + 30000).toDouble()), isBold: true),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: isBold ? Colors.black : Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pastelPinkDark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: _placeOrder,
          child: const Text(
            "ĐẶT HÀNG",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Kiểm tra theo 2 cách
    final firebaseUser = authProvider.firebaseUser;           // User từ FirebaseAuth
    final appUser = authProvider.currentUser;

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập lại để đặt hàng")),
      );
      return;
    }

    // Ưu tiên dùng firebaseUser.uid
    final userId = firebaseUser.uid;

    final order = Order(
      id: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      items: widget.selectedItems.map((item) => OrderItem(
        productId: item.productId,
        title: item.title,
        price: item.price,
        quantity: item.quantity,
        color: item.color,
        size: item.size,
        thumbnail: item.thumbnail,
      )).toList(),
      totalAmount: _totalAmount + 30000,
      paymentMethod: _selectedPaymentMethod,
      shippingAddress: _shippingAddress,
      createdAt: DateTime.now(),
    );

    bool success = await orderProvider.createOrder(order);

    if (success && mounted) {
      for (var item in widget.selectedItems) {
        await cartProvider.removeItem(item.productId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đặt hàng thành công! Cảm ơn bạn đã mua hàng 💖"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.errorMessage ?? "Đặt hàng thất bại")),
      );
    }
  }
}
