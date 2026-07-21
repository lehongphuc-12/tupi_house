import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import 'management/admin_management_screens.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();

      if (auth.isAdmin) {
        context.read<AdminProvider>().loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Chặn người dùng không phải Admin truy cập trực tiếp.
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Không có quyền truy cập'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bạn không có quyền truy cập trang quản trị',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chỉ tài khoản Admin đang hoạt động mới được phép truy cập.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final adminProvider = context.watch<AdminProvider>();

    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final stats = [
      _Stat(
        'Sản phẩm',
        '${adminProvider.products.length}',
        Icons.inventory_2_outlined,
      ),
      _Stat(
        'Danh mục',
        '${adminProvider.categories.length}',
        Icons.category_outlined,
      ),
      _Stat(
        'Người dùng',
        '${adminProvider.users.length}',
        Icons.people_outline,
      ),
      _Stat(
        'Đơn hàng',
        '${adminProvider.orders.length}',
        Icons.receipt_long_outlined,
      ),
      _Stat(
        'Doanh thu',
        money.format(adminProvider.revenue),
        Icons.payments_outlined,
      ),
    ];

    final modules = [
      const _Module(
        'Sản phẩm',
        'Thêm, sửa, xóa và quản lý kho',
        Icons.inventory_2_outlined,
        AdminProductScreen(),
      ),
      const _Module(
        'Danh mục',
        'Quản lý danh mục sản phẩm',
        Icons.category_outlined,
        AdminCategoryScreen(),
      ),
      const _Module(
        'Đơn hàng',
        'Theo dõi và cập nhật trạng thái',
        Icons.receipt_long_outlined,
        AdminOrderScreen(),
      ),
      const _Module(
        'Người dùng',
        'Quản lý vai trò và trạng thái',
        Icons.people_outline,
        AdminUserScreen(),
      ),
      const _Module(
        'Voucher',
        'Tạo và quản lý mã giảm giá',
        Icons.local_offer_outlined,
        AdminVoucherScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: adminProvider.loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Admin
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE3ED),
                            Color(0xFFFFF4F8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFD7E5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 42,
                            color: AppColors.pastelPinkDark,
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quản trị hệ thống',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.pastelPinkDark,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Theo dõi và quản lý toàn bộ hoạt động của Tupi House',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (adminProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),

                    if (adminProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          adminProvider.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),

                    const Text(
                      'Tổng quan',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisExtent: 135,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final stat = stats[index];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  stat.icon,
                                  color: AppColors.pastelPinkDark,
                                ),
                                const Spacer(),
                                Text(
                                  stat.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  stat.title,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Quản lý',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modules.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 390,
                        mainAxisExtent: 135,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final module = modules[index];

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => module.screen,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.softPink,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      module.icon,
                                      color: AppColors.pastelPinkDark,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          module.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          module.subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat {
  final String title;
  final String value;
  final IconData icon;

  const _Stat(
    this.title,
    this.value,
    this.icon,
  );
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  const _Module(
    this.title,
    this.subtitle,
    this.icon,
    this.screen,
  );
}
