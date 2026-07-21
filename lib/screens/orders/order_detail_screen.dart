import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_status_badge.dart';
import '../product/add_review_bottom_sheet.dart';
import 'order_tracking_widget.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  String _formatPrice(int price) {
    final fmt =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return fmt.format(price);
  }

  String _formatDate(DateTime dt) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cod':
        return 'Thanh toán khi nhận hàng (COD)';
      case 'bank':
        return 'Chuyển khoản ngân hàng';
      case 'momo':
        return 'Ví MoMo';
      default:
        return method;
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Bạn có chắc muốn hủy đơn hàng này không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ đơn'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<OrderProvider>().cancelOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '✅ Đã hủy đơn hàng thành công'
                : '❌ Hủy đơn thất bại'),
          ),
        );
        if (success) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final address = order.shippingAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('#$shortId'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OrderStatusBadge(status: order.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tracking Timeline ──────────────────────────────
            OrderTrackingWidget(currentStatus: order.status),
            const SizedBox(height: 16),

            // ── Thông tin đơn hàng ─────────────────────────────
            _SectionCard(
              title: 'Thông tin đơn hàng',
              icon: Icons.receipt_long_outlined,
              children: [
                _InfoRow(label: 'Mã đơn hàng', value: '#$shortId'),
                _InfoRow(
                    label: 'Ngày đặt', value: _formatDate(order.createdAt)),
                _InfoRow(
                    label: 'Trạng thái',
                    value: OrderStatusBadge.label(order.status)),
                _InfoRow(
                    label: 'Thanh toán',
                    value: order.paymentStatus == 'paid'
                        ? 'Đã thanh toán'
                        : 'Chưa thanh toán'),
                _InfoRow(
                    label: 'Phương thức',
                    value: _paymentLabel(order.paymentMethod)),
              ],
            ),
            const SizedBox(height: 12),

            // ── Địa chỉ giao hàng ──────────────────────────────
            _SectionCard(
              title: 'Địa chỉ giao hàng',
              icon: Icons.location_on_outlined,
              children: [
                if (address['name'] != null)
                  _InfoRow(label: 'Người nhận', value: address['name']),
                if (address['phone'] != null)
                  _InfoRow(label: 'Số điện thoại', value: address['phone']),
                if (address['address'] != null)
                  _InfoRow(label: 'Địa chỉ', value: address['address']),
                if (address.isEmpty)
                  const Text('Chưa có thông tin địa chỉ',
                      style: TextStyle(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 12),

            // ── Sản phẩm đã đặt ────────────────────────────────
            _SectionCard(
              title: 'Sản phẩm đã đặt (${order.items.length})',
              icon: Icons.shopping_bag_outlined,
              children: order.items
                  .map((item) => _OrderItemRow(
                        item: item,
                        orderStatus: order.status,
                        formatPrice: _formatPrice,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // ── Tổng tiền ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.softPink, AppColors.softGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0E8EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _formatPrice(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.pastelPinkDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Nút hủy đơn ───────────────────────────────────
            if (order.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _confirmCancel(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(
                    'Hủy đơn hàng',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Helper widgets
// ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.pastelPinkDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0E8EB)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value?.toString() ?? '–',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatefulWidget {
  final OrderItem item;
  final String orderStatus;
  final String Function(int) formatPrice;

  const _OrderItemRow({
    required this.item,
    required this.orderStatus,
    required this.formatPrice,
  });

  @override
  State<_OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<_OrderItemRow> {
  bool _hasReviewed = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderStatus == 'delivered') {
      _checkReviewStatus();
    }
  }

  Future<void> _checkReviewStatus() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.currentUser != null) {
      setState(() => _isChecking = true);
      final reviewed = await ReviewService()
          .hasUserReviewed(auth.currentUser!.id, widget.item.productId);
      if (mounted) {
        setState(() {
          _hasReviewed = reviewed;
          _isChecking = false;
        });
      }
    }
  }

  void _openReviewSheet() async {
    final productDummy = Product(
      id: widget.item.productId,
      title: widget.item.title,
      price: widget.item.price,
      thumbnail: widget.item.thumbnail,
      images: [widget.item.thumbnail],
      description: '',
      categoryId: '',
      categoryName: '',
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReviewBottomSheet(product: productDummy),
    );

    if (result == true && mounted) {
      // Instant UI Refresh chuyển ngay sang trạng thái "Đã đánh giá"
      setState(() {
        _hasReviewed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = widget.orderStatus == 'delivered';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: widget.item.thumbnail.isNotEmpty
                    ? Image.network(
                        widget.item.thumbnail,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderThumb(),
                      )
                    : _PlaceholderThumb(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (widget.item.color != null &&
                            widget.item.color!.isNotEmpty)
                          _Tag('Màu: ${widget.item.color}'),
                        if (widget.item.size != null &&
                            widget.item.size!.isNotEmpty)
                          _Tag('Size: ${widget.item.size}'),
                        _Tag('x${widget.item.quantity}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.formatPrice(widget.item.price * widget.item.quantity),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pastelPinkDark,
                ),
              ),
            ],
          ),

          // ── Nút Đánh giá sản phẩm (chỉ khi đơn hàng ở trạng thái Delivered) ──
          if (isDelivered) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isChecking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_hasReviewed)
                  // Nhãn "Đã đánh giá" (màu xanh lá pastel kèm icon check)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.pastelGreen),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.pastelGreenDark,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đã đánh giá',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pastelGreenDark,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Nút "Đánh giá sản phẩm" cho phép gửi nhận xét 1 lần
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _openReviewSheet,
                    icon: const Icon(Icons.rate_review_outlined, size: 15),
                    label: const Text(
                      'Đánh giá sản phẩm',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style:
              const TextStyle(fontSize: 11, color: AppColors.pastelPinkDark)),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.softPink,
      child: const Icon(Icons.image_outlined,
          color: AppColors.pastelPinkDark, size: 28),
    );
  }
}
