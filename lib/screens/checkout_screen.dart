import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/voucher.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/voucher_provider.dart';
import '../services/voucher_service.dart';

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

  late Map<String, dynamic> _shippingAddress;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _shippingAddress = {
      'fullName': user?.fullName ?? '',
      'phone': user?.phone ?? '',
      'address': '',
      'ward': '',
      'district': '',
      'city': '',
    };
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
    try {
      Provider.of<VoucherProvider>(context, listen: false).removeVoucher();
    } catch (_) {}
    super.dispose();
  }

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

      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 768;

      Widget addressWidget = _buildShippingAddress();
      Widget productsWidget = _buildSelectedProducts(isMobile);
      Widget voucherLoyaltyWidget = _buildVoucherAndLoyaltySection(
          subtotal, userPoints, userTier, voucherProvider, voucherDiscount);
      Widget paymentMethodWidget = _buildPaymentMethod();
      Widget noteWidget = _buildNoteSection();
      Widget paymentDetailsWidget = _buildPaymentDetails(subtotal, tierDiscount,
          voucherDiscount, pointsDiscount, shippingFee, total);

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Thanh toán",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.ink,
            ),
          ),
        ),
        body: isMobile
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    addressWidget,
                    const SizedBox(height: 14),
                    productsWidget,
                    const SizedBox(height: 14),
                    voucherLoyaltyWidget,
                    const SizedBox(height: 14),
                    paymentMethodWidget,
                    const SizedBox(height: 14),
                    noteWidget,
                    const SizedBox(height: 14),
                    paymentDetailsWidget,
                    const SizedBox(height: 24),
                  ],
                ),
              )
            : _buildDesktopBody(
                addressWidget: addressWidget,
                productsWidget: productsWidget,
                voucherLoyaltyWidget: voucherLoyaltyWidget,
                paymentMethodWidget: paymentMethodWidget,
                noteWidget: noteWidget,
                paymentDetailsWidget: paymentDetailsWidget,
                totalAmount: total,
              ),
        bottomNavigationBar: isMobile ? _buildBottomBar(total) : null,
      );
    } catch (e, stack) {
      debugPrint("CheckoutScreen build error: $e\n$stack");
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lỗi thanh toán"),
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

  Widget _buildDesktopBody({
    required Widget addressWidget,
    required Widget productsWidget,
    required Widget voucherLoyaltyWidget,
    required Widget paymentMethodWidget,
    required Widget noteWidget,
    required Widget paymentDetailsWidget,
    required int totalAmount,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      addressWidget,
                      const SizedBox(height: 16),
                      productsWidget,
                      const SizedBox(height: 16),
                      voucherLoyaltyWidget,
                      const SizedBox(height: 16),
                      paymentMethodWidget,
                      const SizedBox(height: 16),
                      noteWidget,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),

              // Right Column (Summary Card)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outlineSoft, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      paymentDetailsWidget,
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _placeOrder(totalAmount),
                          child: const Text(
                            "ĐẶT HÀNG",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primaryPink, size: 20),
              const SizedBox(width: 8),
              const Text("Địa chỉ giao hàng",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
              const Spacer(),
              TextButton(
                  onPressed: _showEditAddressDialog,
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryPink),
                  child: const Text("Thay đổi", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Text(_shippingAddress['fullName'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(_shippingAddress['phone'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(_shippingAddress['address'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
          Text(
              "${_shippingAddress['ward']}, ${_shippingAddress['district']}, ${_shippingAddress['city']}",
              style: const TextStyle(color: AppColors.textSecondary)),
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
        InputDecoration inputStyle(String label, [IconData? icon]) =>
            InputDecoration(
              labelText: label,
              prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.primaryPink) : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            );

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: const Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: AppColors.primaryPink),
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
                            borderRadius: BorderRadius.circular(10))),
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
                            borderRadius: BorderRadius.circular(10))),
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

  Widget _buildSelectedProducts(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Sản phẩm",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
          ),
          ...widget.selectedItems.map((item) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 50,
                  height: 50,
                  color: AppColors.surfaceVariant,
                  child: item.thumbnail.isNotEmpty
                      ? Image.network(item.thumbnail,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.local_florist_outlined, size: 24, color: AppColors.muted))
                      : const Icon(Icons.local_florist_outlined, size: 24, color: AppColors.muted),
                ),
              ),
              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(
                "${item.color != null ? 'Màu: ${item.color} ' : ''}${item.size != null ? 'Size: ${item.size}' : ''}",
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatVnd(item.price.toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryPink, fontSize: 13.5)),
                  Text("x${item.quantity}", style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Phương thức thanh toán",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 12),
          _paymentOption(
              "Thanh toán khi nhận hàng (COD)", "cod", Icons.delivery_dining_rounded),
          _paymentOption(
              "Chuyển khoản ngân hàng", "bank", Icons.account_balance_rounded),
          _paymentOption("Ví MoMo", "momo", Icons.wallet_rounded),
          _paymentOption("ZaloPay / VNPay", "vnpay", Icons.payment_rounded),
        ],
      ),
    );
  }

  Widget _paymentOption(String title, String method, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.softPink.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryPink.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon, color: isSelected ? AppColors.primaryPink : AppColors.muted),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 13.5)),
        trailing: Radio<String>(
          value: method,
          groupValue: _selectedPaymentMethod,
          activeColor: AppColors.primaryPink,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
        ),
        onTap: () => setState(() => _selectedPaymentMethod = method),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ghi chú cho người bán",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: "Ví dụ: Gọi trước khi giao hàng...",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.outlineSoft)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(int subtotal, int tierDiscount,
      int voucherDiscount, int pointsDiscount, int shippingFee, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Chi tiết thanh toán",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 12),
          _detailRow("Tổng tiền hàng", formatVnd(subtotal.toDouble())),
          if (tierDiscount > 0)
            _detailRow("Giảm giá thành viên",
                "-${formatVnd(tierDiscount.toDouble())}", valueColor: AppColors.primaryPink),
          if (voucherDiscount > 0)
            _detailRow("Voucher giảm giá",
                "-${formatVnd(voucherDiscount.toDouble())}", valueColor: AppColors.primaryPink),
          if (pointsDiscount > 0)
            _detailRow(
                "Đổi điểm thưởng", "-${formatVnd(pointsDiscount.toDouble())}", valueColor: AppColors.primaryPink),
          _detailRow(
              "Phí vận chuyển",
              shippingFee == 0
                  ? "Freeship"
                  : formatVnd(shippingFee.toDouble()), valueColor: shippingFee == 0 ? AppColors.pastelGreenDark : AppColors.ink),
          const Divider(),
          _detailRow("Tổng thanh toán", formatVnd(total.toDouble()),
              isBold: true, fontSize: 17, valueColor: AppColors.primaryPink),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, double fontSize = 13.5, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                  color: isBold ? AppColors.ink : AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  color: valueColor ?? (isBold ? AppColors.ink : AppColors.ink),
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.w700)),
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
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _placeOrder(totalAmount),
          child: const Text(
            "ĐẶT HÀNG",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
      if (pointsToUse > 0) {
        await authProvider.updateUserPoints(-pointsToUse);
      }

      if (voucherProvider.appliedVoucher != null) {
        await voucherProvider.useAppliedVoucher();
      }

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
      String tier, VoucherProvider voucherProvider, int voucherDiscount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ưu đãi & Khách hàng thân thiết 🎁",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hạng thành viên:", style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
              Text(
                tier,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPink),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Nhập mã voucher...",
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    voucherProvider.applyVoucher(
                        _voucherController.text, subtotal);
                  },
                  child: const Text("Áp dụng", style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),

          if (voucherProvider.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              voucherProvider.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],

          if (voucherProvider.appliedVoucher != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Đã áp dụng: ${voucherProvider.appliedVoucher!.code} (Giảm ${formatVnd(voucherDiscount.toDouble())})",
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
                      const Text("Gỡ bỏ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dùng điểm Tupi Loyalty (Còn: $userPoints)",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const Text("Quy đổi: 1 điểm = 1.000đ",
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              Switch(
                value: _usePoints,
                activeTrackColor: AppColors.primaryPinkLight,
                activeColor: AppColors.primaryPink,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Chuyển khoản thanh toán",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Quét mã QR dưới đây bằng ứng dụng ngân hàng của bạn để thanh toán.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: AppColors.surfaceVariant,
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  qrUrl,
                  height: 230,
                  width: 230,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      size: 50,
                      color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text("Số tiền: ${formatVnd(amount.toDouble())}",
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.primaryPink)),
            const SizedBox(height: 8),
            Text("Nội dung: $orderId",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 16),
            const Text(
                "Sau khi chuyển khoản thành công, vui lòng nhấn nút bên dưới.",
                style: TextStyle(color: AppColors.muted, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }
}
