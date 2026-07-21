import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/seed_orders.dart';
import '../../widgets/order_status_badge.dart';
import '../login_screen.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    _TabDef(label: 'Tất cả', filter: 'all'),
    _TabDef(label: 'Đang xử lý', filter: 'active'),
    _TabDef(label: 'Đang giao', filter: 'shipping'),
    _TabDef(label: 'Đã giao', filter: 'delivered'),
    _TabDef(label: 'Đã hủy', filter: 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn && auth.firebaseUser != null) {
        context.read<OrderProvider>().listenToOrders(auth.firebaseUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Order> _filteredOrders(OrderProvider provider, String filter) {
    switch (filter) {
      case 'active':
        return provider.orders
            .where((o) => o.status == 'pending' || o.status == 'confirmed')
            .toList();
      case 'shipping':
        return provider.orders.where((o) => o.status == 'shipping').toList();
      case 'delivered':
        return provider.deliveredOrders;
      case 'cancelled':
        return provider.cancelledOrders;
      default:
        return provider.allOrders;
    }
  }

  Future<void> _seedOrders(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo đơn hàng mẫu?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Sẽ tạo 6 đơn hàng mẫu gồm đủ các trạng thái:\n'
            '• 1 Chờ xác nhận\n'
            '• 1 Đã xác nhận\n'
            '• 1 Đang giao hàng\n'
            '• 2 Đã giao hàng\n'
            '• 1 Đã hủy'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tạo ngay'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏳ Đang tạo đơn hàng mẫu...')),
    );

    try {
      await SeedOrders.seed(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã tạo 6 đơn hàng mẫu thành công!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _clearOrders(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả đơn hàng?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Hành động này sẽ xóa TOÀN BỘ đơn hàng của tài khoản này. Không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa hết'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SeedOrders.clearUserOrders(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Đã xóa tất cả đơn hàng')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Kiểm tra đăng nhập chặt chẽ hơn
    if (!auth.isLoggedIn || auth.firebaseUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đơn hàng của tôi')),
        body: _NotLoggedIn(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Công cụ test',
            onSelected: (value) async {
              final uid = auth.firebaseUser!.uid;
              if (value == 'seed') {
                await _seedOrders(context, uid);
              } else if (value == 'clear') {
                await _clearOrders(context, uid);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    Icon(Icons.add_shopping_cart,
                        size: 18, color: AppColors.pastelGreenDark),
                    SizedBox(width: 10),
                    Text('Tạo đơn mẫu (6 đơn)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Xóa tất cả đơn hàng',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.pastelPinkDark,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.pastelPinkDark,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 56, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          provider.listenToOrders(auth.firebaseUser!.uid),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final orders = _filteredOrders(provider, tab.filter);
              return _OrderList(orders: orders);
            }).toList(),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Order List
// ──────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Order> orders;

  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.softPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: AppColors.pastelPinkDark,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy đặt hàng để xem lịch sử tại đây nhé!',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Order Card
// ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(price);
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E8EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: mã đơn + badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.receipt_outlined,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    '#$shortId',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  OrderStatusBadge(status: order.status),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF5EFF2)),

            // Product preview
            if (firstItem != null)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: firstItem.thumbnail.isNotEmpty
                          ? Image.network(
                              firstItem.thumbnail,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                            )
                          : _thumbPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem.title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order.items.length > 1) ...[
                            const SizedBox(height: 3),
                            Text(
                              '+${order.items.length - 1} sản phẩm khác',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Footer: ngày đặt + tổng tiền
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFAFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(order.createdAt),
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const Spacer(),
                  Text(
                    _formatPrice(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.pastelPinkDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined,
          color: AppColors.pastelPinkDark, size: 24),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Not logged in state
// ──────────────────────────────────────────────────────────────

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.softPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  size: 52, color: AppColors.pastelPinkDark),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đăng nhập để xem đơn hàng',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vui lòng đăng nhập để xem lịch sử và theo dõi đơn hàng của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final String filter;
  const _TabDef({required this.label, required this.filter});
}
