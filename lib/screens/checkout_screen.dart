import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart.dart';
import '../../models/order.dart';
import '../../models/voucher.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/voucher_provider.dart';
import '../../services/voucher_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;

  const CheckoutScreen({super.key, required this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'cod'; // cod, bank, momo, vnpay
  final TextEditingController _noteController = TextEditingController();
  bool _usePoints = false;
  final TextEditingController _voucherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<VoucherProvider>(context, listen: false).removeVoucher();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _voucherController.dispose();
    // Safely remove voucher on dispose to avoid residual discount states
    try {
      Provider.of<VoucherProvider>(context, listen: false).removeVoucher();
    } catch (_) {}
    super.dispose();
  }

  // Địa chỉ giao hàng mẫu (sau này lấy từ user profile)
  Map<String, dynamic> _shippingAddress = {
    'fullName': 'Nguyễn Văn A',
    'phone': '0123456789',
    'address': '123 Đường ABC, Phường XYZ',
    'ward': 'Phường 1',
    'district': 'Quận 1',
    'city': 'TP. Hồ Chí Minh',
  };

  int get _subtotalAmount => widget.selectedItems
      .fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    try {
      final auth = context.watch<AuthProvider>();
      final user = auth.currentUser;
      final userTier = user?.tier ?? 'Đồng';
      final userPoints = user?.points ?? 0;

      int subtotal = _subtotalAmount;

      // Tính toán giảm giá theo hạng thành viên (Tier Discount)
      double tierDiscountRate = 0.0;
      bool isFreeship = false;
      if (userTier == 'Bạc') {
        tierDiscountRate = 0.02;
      } else if (userTier == 'Vàng') {
        tierDiscountRate = 0.05;
        isFreeship = true;
      } else if (userTier == 'Kim Cương') {
        tierDiscountRate = 0.10;
        isFreeship = true;
      }
      int tierDiscount = (subtotal * tierDiscountRate).floor();
      int shippingFee = isFreeship ? 0 : 30000;

      // Giảm giá từ Voucher
      final voucherProvider = context.watch<VoucherProvider>();
      int voucherDiscount = voucherProvider.discountAmount;

      // Giảm giá từ đổi điểm thưởng
      int pointsDiscount = 0;
      if (_usePoints && userPoints > 0) {
        int maxPointsDiscount =
            subtotal + shippingFee - tierDiscount - voucherDiscount;
        if (maxPointsDiscount < 0) maxPointsDiscount = 0;
        int userPointsValue = userPoints * 1000;
        if (userPointsValue > maxPointsDiscount) {
          pointsDiscount = maxPointsDiscount;
        } else {
          pointsDiscount = userPointsValue;
        }
      }

      int total = subtotal +
          shippingFee -
          tierDiscount -
          voucherDiscount -
          pointsDiscount;
      if (total < 0) total = 0;

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
                child: Text("Sản phẩm (${widget.selectedItems.length})",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildSelectedProducts(),

              const Divider(height: 8),

              // 2b. Ưu đãi & Khách hàng thân thiết
              _buildVoucherAndLoyaltySection(
                  subtotal, userPoints, userTier, voucherProvider),

              const Divider(height: 8),

              // 3. Phương thức thanh toán
              _buildPaymentMethod(),

              // 4. Ghi chú
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ghi chú cho người bán",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Ví dụ: Gọi trước khi giao hàng...",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Chi tiết thanh toán
              _buildPaymentDetails(subtotal, tierDiscount, voucherDiscount,
                  pointsDiscount, shippingFee, total),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(total),
      );
    } catch (e, stack) {
      debugPrint("CheckoutScreen build error: $e\n$stack");
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lỗi thanh toán"),
          backgroundColor: Colors.red,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Đã xảy ra lỗi khi tải trang thanh toán:\n$e",
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text("Stack Trace:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text(
                  stack.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
              const Text("Địa chỉ giao hàng",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              TextButton(
                  onPressed: _showEditAddressDialog,
                  child: const Text("Thay đổi")),
            ],
          ),
          const SizedBox(height: 8),
          Text(_shippingAddress['fullName'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_shippingAddress['phone'] ?? ''),
          const SizedBox(height: 4),
          Text(_shippingAddress['address'] ?? ''),
          Text(
              "${_shippingAddress['ward']}, ${_shippingAddress['district']}, ${_shippingAddress['city']}"),
        ],
      ),
    );
  }

  void _showEditAddressDialog() {
    final nameController =
        TextEditingController(text: _shippingAddress['fullName']);
    final phoneController =
        TextEditingController(text: _shippingAddress['phone']);
    final addressController =
        TextEditingController(text: _shippingAddress['address']);
    final wardController =
        TextEditingController(text: _shippingAddress['ward']);
    final districtController =
        TextEditingController(text: _shippingAddress['district']);
    final cityController =
        TextEditingController(text: _shippingAddress['city']);

    showDialog(
      context: context,
      builder: (context) {
        // Styling chung cho input để tái sử dụng ngắn gọn
        InputDecoration inputStyle(String label, [IconData? icon]) =>
            InputDecoration(
              labelText: label,
              prefixIcon: icon != null ? Icon(icon, size: 20) : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            );

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Thay đổi địa chỉ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: inputStyle('Họ và tên', Icons.person_outline)),
                const SizedBox(height: 10),
                TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration:
                        inputStyle('Số điện thoại', Icons.phone_outlined)),
                const SizedBox(height: 10),
                TextField(
                    controller: addressController,
                    textInputAction: TextInputAction.next,
                    decoration: inputStyle(
                        'Địa chỉ (Số nhà, đường)', Icons.home_outlined)),
                const SizedBox(height: 10),
                TextField(
                    controller: cityController,
                    textInputAction: TextInputAction.next,
                    decoration: inputStyle(
                        'Tỉnh/Thành phố', Icons.location_city_outlined)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: districtController,
                            textInputAction: TextInputAction.next,
                            decoration: inputStyle('Quận/Huyện'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: wardController,
                            textInputAction: TextInputAction.done,
                            decoration: inputStyle('Phường/Xã'))),
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
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
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
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
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
    return Column(
      children: widget.selectedItems.map((item) {
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.thumbnail.isNotEmpty
                ? Image.network(item.thumbnail,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, size: 60))
                : const Icon(Icons.image, size: 60),
          ),
          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            "${item.color != null ? 'Màu: ${item.color} ' : ''}${item.size != null ? 'Size: ${item.size}' : ''}",
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatVnd(item.price.toDouble()),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("x${item.quantity}"),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Phương thức thanh toán",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _paymentOption(
              "Thanh toán khi nhận hàng (COD)", "cod", Icons.delivery_dining),
          _paymentOption(
              "Chuyển khoản ngân hàng", "bank", Icons.account_balance),
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

  Widget _buildPaymentDetails(int subtotal, int tierDiscount,
      int voucherDiscount, int pointsDiscount, int shippingFee, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Chi tiết thanh toán",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _detailRow("Tổng tiền hàng", formatVnd(subtotal.toDouble())),
          if (tierDiscount > 0)
            _detailRow("Giảm giá thành viên",
                "-${formatVnd(tierDiscount.toDouble())}"),
          if (voucherDiscount > 0)
            _detailRow("Voucher giảm giá",
                "-${formatVnd(voucherDiscount.toDouble())}"),
          if (pointsDiscount > 0)
            _detailRow(
                "Đổi điểm thưởng", "-${formatVnd(pointsDiscount.toDouble())}"),
          _detailRow(
              "Phí vận chuyển",
              shippingFee == 0
                  ? "Freeship"
                  : formatVnd(shippingFee.toDouble())),
          const Divider(),
          _detailRow("Tổng thanh toán", formatVnd(total.toDouble()),
              isBold: true),
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
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  color: isBold ? Colors.black : Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int totalAmount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pastelPinkDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () => _placeOrder(totalAmount),
        child: const Text(
          "ĐẶT HÀNG",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _placeOrder(int totalAmount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final voucherProvider =
        Provider.of<VoucherProvider>(context, listen: false);

    final firebaseUser = authProvider.firebaseUser;
    final appUser = authProvider.currentUser;

    if (firebaseUser == null || appUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập lại để đặt hàng")),
      );
      return;
    }

    final userId = firebaseUser.uid;
    int subtotal = _subtotalAmount;

    // Tính toán giảm giá theo hạng thành viên
    double tierDiscountRate = 0.0;
    bool isFreeship = false;
    if (appUser.tier == 'Bạc') {
      tierDiscountRate = 0.02;
    } else if (appUser.tier == 'Vàng') {
      tierDiscountRate = 0.05;
      isFreeship = true;
    } else if (appUser.tier == 'Kim Cương') {
      tierDiscountRate = 0.10;
      isFreeship = true;
    }
    int tierDiscount = (subtotal * tierDiscountRate).floor();
    int shippingFee = isFreeship ? 0 : 30000;

    int voucherDiscount = voucherProvider.discountAmount;

    // Điểm sử dụng
    int pointsToUse = 0;
    int pointsDiscount = 0;
    if (_usePoints && appUser.points > 0) {
      int maxPointsDiscount =
          subtotal + shippingFee - tierDiscount - voucherDiscount;
      if (maxPointsDiscount < 0) maxPointsDiscount = 0;
      int userPointsValue = appUser.points * 1000;
      if (userPointsValue > maxPointsDiscount) {
        pointsDiscount = maxPointsDiscount;
        pointsToUse = (pointsDiscount / 1000.0).ceil();
      } else {
        pointsDiscount = userPointsValue;
        pointsToUse = appUser.points;
      }
    }

    final order = Order(
      id: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      items: widget.selectedItems
          .map((item) => OrderItem(
                productId: item.productId,
                title: item.title,
                price: item.price,
                quantity: item.quantity,
                color: item.color,
                size: item.size,
                thumbnail: item.thumbnail,
              ))
          .toList(),
      subtotalAmount: subtotal,
      discountAmount: tierDiscount + voucherDiscount + pointsDiscount,
      shippingFee: shippingFee,
      totalAmount: totalAmount,
      voucherCode: voucherProvider.appliedVoucher?.code,
      pointsUsed: pointsToUse,
      paymentMethod: _selectedPaymentMethod,
      shippingAddress: _shippingAddress,
      createdAt: DateTime.now(),
    );

    bool success = await orderProvider.createOrder(order);

    if (success && mounted) {
      // 1. Trừ điểm người dùng
      if (pointsToUse > 0) {
        await authProvider.updateUserPoints(-pointsToUse);
      }

      // 2. Sử dụng voucher
      if (voucherProvider.appliedVoucher != null) {
        await voucherProvider.useAppliedVoucher();
      }

      // 3. Xóa sản phẩm khỏi giỏ hàng
      for (var item in widget.selectedItems) {
        await cartProvider.removeItem(item.productId);
      }

      if (_selectedPaymentMethod == 'bank') {
        _showVietQRDialog(order.id, totalAmount);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đặt hàng thành công! Cảm ơn bạn đã mua hàng 💖"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(orderProvider.errorMessage ?? "Đặt hàng thất bại")),
      );
    }
  }

  Widget _buildVoucherAndLoyaltySection(int subtotal, int userPoints,
      String tier, VoucherProvider voucherProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ưu đãi & Khách hàng thân thiết 🎁",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          // Hạng thành viên hiện tại
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hạng thành viên:", style: TextStyle(fontSize: 14)),
              Text(
                tier,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.pastelPinkDark),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nhập voucher
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    hintText: "Nhập mã voucher...",
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    voucherProvider.applyVoucher(
                        _voucherController.text, subtotal);
                  },
                  child: const Text("Áp dụng"),
                ),
              ),
            ],
          ),

          if (voucherProvider.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              voucherProvider.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],

          if (voucherProvider.appliedVoucher != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Đã áp dụng: ${voucherProvider.appliedVoucher!.code} (Giảm ${formatVnd(voucherDiscount(voucherProvider.appliedVoucher!, subtotal).toDouble())})",
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _voucherController.clear();
                    voucherProvider.removeVoucher();
                  },
                  child:
                      const Text("Gỡ bỏ", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],

          const Divider(height: 24),

          // Tích điểm & Dùng điểm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dùng điểm Tupi Loyalty (Còn: $userPoints)",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("Quy đổi: 1 điểm = 1.000đ",
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Switch(
                value: _usePoints,
                activeColor: Colors.white,
                activeTrackColor: AppColors.pastelPinkDark,
                onChanged: userPoints > 0
                    ? (val) {
                        setState(() {
                          _usePoints = val;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int voucherDiscount(Voucher voucher, int subtotal) {
    return VoucherService().calculateDiscount(voucher, subtotal);
  }

  void _showVietQRDialog(String orderId, int amount) {
    const bankId = "MB";
    const accountNo = "0788580223";
    const accountName = "LE HONG PHUC";
    final qrUrl =
        "https://img.vietqr.io/image/$bankId-$accountNo-compact.png?amount=$amount&addInfo=$orderId&accountName=$accountName";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Chuyển khoản thanh toán",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Quét mã QR dưới đây bằng ứng dụng ngân hàng của bạn để thanh toán.",
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                qrUrl,
                height: 250,
                width: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Text("Số tiền: ${formatVnd(amount.toDouble())}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.pastelPinkDark)),
            const SizedBox(height: 8),
            Text("Nội dung: $orderId",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
                "Sau khi chuyển khoản thành công, vui lòng nhấn nút bên dưới.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pastelPinkDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: () {
                Navigator.pop(context); // Đóng dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          "Đặt hàng thành công! Chúng tôi sẽ kiểm tra thanh toán và giao hàng."),
                      backgroundColor: Colors.green),
                );
                Navigator.popUntil(
                    context, (route) => route.isFirst); // Về trang chủ
              },
              child: const Text("TÔI ĐÃ THANH TOÁN",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
