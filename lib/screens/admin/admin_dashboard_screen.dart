import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import 'management/admin_management_screens.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAdmin) context.read<AdminProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) return const _AccessDeniedScreen();

    final admin = context.watch<AdminProvider>();
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final revenuePoints = admin.revenueData(
      _selectedPeriod,
      maxPoints: _selectedPeriod == AnalyticsPeriod.month ? 12 : 10,
    );
    final topProducts = admin.topSellingProducts(limit: 10);
    final pendingOrders = admin.orderCountByStatus['pending'] ?? 0;
    final lowStockProducts =
        admin.products.where((product) => product.stock < 5).length;

    final stats = [
      _Stat('Tổng doanh thu', money.format(admin.revenue),
          Icons.payments_outlined),
      _Stat('Đơn thành công', '${admin.deliveredOrderCount}',
          Icons.check_circle_outline),
      _Stat(
          'Đơn đã hủy', '${admin.cancelledOrderCount}', Icons.cancel_outlined),
      _Stat('Tỷ lệ hủy', '${admin.cancellationRate.toStringAsFixed(1)}%',
          Icons.percent),
    ];

    final modules = [
      const _Module('Sản phẩm', 'Thêm, sửa, xóa và quản lý kho',
          Icons.inventory_2_outlined, AdminProductScreen()),
      const _Module('Danh mục', 'Quản lý danh mục sản phẩm',
          Icons.category_outlined, AdminCategoryScreen()),
      const _Module('Đơn hàng', 'Theo dõi và cập nhật trạng thái',
          Icons.receipt_long_outlined, AdminOrderScreen()),
      const _Module('Người dùng', 'Quản lý vai trò và trạng thái',
          Icons.people_outline, AdminUserScreen()),
      const _Module('Voucher', 'Tạo và quản lý mã giảm giá',
          Icons.local_offer_outlined, AdminVoucherScreen()),
    ];

    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          _AdminAccountMenu(auth: auth),
          const SizedBox(width: 12),
        ],
      ),
        body: RefreshIndicator(
        onRefresh: admin.loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DashboardHeader(),
                    if (admin.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                    if (admin.errorMessage != null)
                      _ErrorBanner(
                        message: admin.errorMessage!,
                        onRetry: admin.loadAll,
                      ),
                    const SizedBox(height: 22),
                    if (pendingOrders > 0 || lowStockProducts > 0) ...[
                      _AttentionCard(
                        pendingOrders: pendingOrders,
                        lowStockProducts: lowStockProducts,
                      ),
                      const SizedBox(height: 28),
                    ],
                    const _SectionTitle(
                      title: 'Tổng quan kinh doanh',
                      subtitle: 'Chỉ tính doanh thu từ đơn hàng đã giao',
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(builder: (_, constraints) {
                      final isSmall = constraints.maxWidth < 340;
                      final itemWidth = isSmall 
                          ? constraints.maxWidth 
                          : (constraints.maxWidth - 12) / 2.001;
                          
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: stats.map((stat) {
                          return SizedBox(
                            width: itemWidth,
                            child: _StatCard(stat: stat),
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 30),
                    _AnalyticsCard(
                      selectedPeriod: _selectedPeriod,
                      points: revenuePoints,
                      money: money,
                      onPeriodChanged: (value) {
                        setState(() => _selectedPeriod = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final status = _OrderStatusCard(admin: admin);
                        final top = _TopProductsCard(
                          products: topProducts,
                          money: money,
                        );
                        if (constraints.maxWidth < 850) {
                          return Column(
                            children: [
                              status,
                              const SizedBox(height: 20),
                              top,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: status),
                            const SizedBox(width: 20),
                            Expanded(flex: 6, child: top),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    const _SectionTitle(
                      title: 'Quản lý hệ thống',
                      subtitle: 'Truy cập nhanh các chức năng quản trị',
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
                      itemBuilder: (_, index) =>
                          _ModuleCard(module: modules[index]),
                    ),
                    const SizedBox(height: 30),
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
}

enum _AdminMenuAction {
  profile,
  changePassword,
  logout,
}

class _AdminAccountMenu extends StatelessWidget {
  final AuthProvider auth;

  const _AdminAccountMenu({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final name = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Admin';
    final email = user?.email ?? '';
    final avatar = user?.avatar ?? '';

    return PopupMenuButton<_AdminMenuAction>(
      tooltip: 'Tài khoản Admin',
      offset: const Offset(0, 54),
      onSelected: (action) async {
        switch (action) {
          case _AdminMenuAction.profile:
            await _showAdminProfileDialog(
              context,
              name: name,
              email: email,
              avatar: avatar,
            );
            break;
          case _AdminMenuAction.changePassword:
            await _showChangePasswordDialog(context, auth);
            break;
          case _AdminMenuAction.logout:
            await _confirmAndLogout(context, auth);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_AdminMenuAction>(
          enabled: false,
          child: SizedBox(
            width: 240,
            child: Row(
              children: [
                _AdminAvatar(
                  name: name,
                  avatar: avatar,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_AdminMenuAction>(
          value: _AdminMenuAction.profile,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline),
            title: Text('Hồ sơ'),
          ),
        ),
        PopupMenuItem<_AdminMenuAction>(
          value: _AdminMenuAction.changePassword,
          enabled: auth.canChangePassword,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Đổi mật khẩu'),
            subtitle: auth.canChangePassword
                ? null
                : const Text(
                    'Tài khoản Google quản lý mật khẩu',
                    style: TextStyle(fontSize: 11),
                  ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_AdminMenuAction>(
          value: _AdminMenuAction.logout,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFD7E5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdminAvatar(
              name: name,
              avatar: avatar,
              radius: 17,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  final String name;
  final String avatar;
  final double radius;

  const _AdminAvatar({
    required this.name,
    required this.avatar,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

    if (avatar.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.softPink,
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.pastelPinkDark,
            fontWeight: FontWeight.w900,
            fontSize: radius * 0.85,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.softPink,
      foregroundImage: NetworkImage(avatar),
      onForegroundImageError: (_, __) {},
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.pastelPinkDark,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}

Future<void> _showAdminProfileDialog(
  BuildContext context, {
  required String name,
  required String email,
  required String avatar,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Hồ sơ Admin'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AdminAvatar(
                name: name,
                avatar: avatar,
                radius: 44,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email.isEmpty ? 'Chưa cập nhật email' : email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softPink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.pastelPinkDark,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vai trò: Quản trị viên hệ thống',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
        ],
      );
    },
  );
}

Future<void> _showChangePasswordDialog(
  BuildContext context,
  AuthProvider auth,
) async {
  if (!auth.canChangePassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AuthProvider.googlePasswordManagedMessage),
      ),
    );
    return;
  }

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var obscureCurrent = true;
  var obscureNew = true;
  var obscureConfirm = true;
  var isSubmitting = false;

  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              setDialogState(() => isSubmitting = true);
              final error = await auth.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );

              if (!dialogContext.mounted) return;
              setDialogState(() => isSubmitting = false);

              if (error != null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(error)),
                );
                return;
              }

              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đổi mật khẩu thành công'),
                ),
              );
            }

            InputDecoration passwordDecoration({
              required String label,
              required bool obscure,
              required VoidCallback onToggle,
            }) {
              return InputDecoration(
                labelText: label,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              );
            }

            return AlertDialog(
              title: const Text('Đổi mật khẩu'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: passwordDecoration(
                          label: 'Mật khẩu hiện tại',
                          obscure: obscureCurrent,
                          onToggle: () {
                            setDialogState(
                              () => obscureCurrent = !obscureCurrent,
                            );
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: passwordDecoration(
                          label: 'Mật khẩu mới',
                          obscure: obscureNew,
                          onToggle: () {
                            setDialogState(() => obscureNew = !obscureNew);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu mới';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                          }
                          if (value == currentPasswordController.text) {
                            return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!isSubmitting) submit();
                        },
                        decoration: passwordDecoration(
                          label: 'Xác nhận mật khẩu mới',
                          obscure: obscureConfirm,
                          onToggle: () {
                            setDialogState(
                              () => obscureConfirm = !obscureConfirm,
                            );
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu mới';
                          }
                          if (value != newPasswordController.text) {
                            return 'Mật khẩu xác nhận không khớp';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cập nhật'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}

Future<void> _confirmAndLogout(
  BuildContext context,
  AuthProvider auth,
) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản Admin không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      );
    },
  );

  if (shouldLogout != true || !context.mounted) return;

  await auth.logout();

  if (!context.mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const LoginScreen(),
    ),
    (route) => false,
  );
}

class _AnalyticsCard extends StatelessWidget {
  final AnalyticsPeriod selectedPeriod;
  final List<RevenueDataPoint> points;
  final NumberFormat money;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;

  const _AnalyticsCard({
    required this.selectedPeriod,
    required this.points,
    required this.money,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _SectionTitle(
                  title: 'Biểu đồ doanh thu',
                  subtitle: 'Gom nhóm các đơn đã giao theo thời gian',
                ),
                SegmentedButton<AnalyticsPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: AnalyticsPeriod.day,
                      label: Text('Ngày'),
                      icon: Icon(Icons.today_outlined),
                    ),
                    ButtonSegment(
                      value: AnalyticsPeriod.week,
                      label: Text('Tuần'),
                      icon: Icon(Icons.date_range_outlined),
                    ),
                    ButtonSegment(
                      value: AnalyticsPeriod.month,
                      label: Text('Tháng'),
                      icon: Icon(Icons.calendar_month_outlined),
                    ),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: (selection) {
                    onPeriodChanged(selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (points.isEmpty)
              const _EmptyState(
                icon: Icons.bar_chart_outlined,
                message: 'Chưa có đơn hàng thành công để vẽ biểu đồ.',
              )
            else
              SizedBox(
                height: 330,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: _chartMaxY(points),
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _chartInterval(points),
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFF0E8EB),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final point = points[group.x];
                          return BarTooltipItem(
                            '${_fullPeriodLabel(point.periodStart, selectedPeriod)}\n'
                            '${money.format(point.revenue)}\n'
                            '${point.orderCount} đơn',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          interval: _chartInterval(points),
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              _compactMoney(value),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 10,
                              child: Text(
                                _shortPeriodLabel(
                                  points[index].periodStart,
                                  selectedPeriod,
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(points.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: points[index].revenue.toDouble(),
                            width: points.length > 8 ? 18 : 28,
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.pastelPink,
                                AppColors.pastelPinkDark,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  duration: const Duration(milliseconds: 500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _chartMaxY(List<RevenueDataPoint> points) {
    final maxRevenue = points.fold<int>(0, (maxValue, point) {
      return math.max(maxValue, point.revenue);
    });
    if (maxRevenue == 0) return 100000;
    return maxRevenue * 1.25;
  }

  static double _chartInterval(List<RevenueDataPoint> points) {
    return _chartMaxY(points) / 5;
  }
}

class _OrderStatusCard extends StatelessWidget {
  final AdminProvider admin;

  const _OrderStatusCard({required this.admin});

  @override
  Widget build(BuildContext context) {
    final statusCounts = admin.orderCountByStatus;
    final total = math.max(1, admin.orders.length);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Trạng thái đơn hàng',
              subtitle: 'Phân bố toàn bộ đơn trong hệ thống',
            ),
            const SizedBox(height: 20),
            if (admin.orders.isEmpty)
              const _EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'Chưa có dữ liệu đơn hàng.',
              )
            else
              ...AdminProvider.validOrderStatuses.map((status) {
                final count = statusCounts[status] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _statusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(admin.orderStatusLabel(status))),
                          Text(
                            '$count',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: count / total,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(99),
                        backgroundColor: const Color(0xFFF3EEF0),
                        color: _statusColor(status),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<TopSellingProduct> products;
  final NumberFormat money;

  const _TopProductsCard({required this.products, required this.money});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Top sản phẩm bán chạy',
              subtitle: 'Xếp hạng theo số lượng từ đơn đã giao',
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              const _EmptyState(
                icon: Icons.emoji_events_outlined,
                message: 'Chưa có sản phẩm bán thành công.',
              )
            else
              ...List.generate(products.length, (index) {
                final item = products[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == products.length - 1 ? 0 : 12,
                  ),
                  child: Row(
                    children: [
                      _RankBadge(rank: index + 1),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 54,
                          height: 54,
                          child: item.thumbnail.isEmpty
                              ? const ColoredBox(
                                  color: AppColors.softPink,
                                  child: Icon(Icons.image_outlined),
                                )
                              : Image.network(
                                  item.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(
                                    color: AppColors.softPink,
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title.isEmpty
                                  ? 'Sản phẩm không xác định'
                                  : item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Doanh thu ${money.format(item.revenue)}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.quantitySold}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.pastelPinkDark,
                            ),
                          ),
                          const Text(
                            'đã bán',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final int pendingOrders;
  final int lowStockProducts;

  const _AttentionCard({
    required this.pendingOrders,
    required this.lowStockProducts,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (pendingOrders > 0)
        _AttentionRow(
          icon: Icons.pending_actions_outlined,
          title: 'Đơn chờ xác nhận',
          detail: '$pendingOrders đơn cần được xử lý',
          color: Colors.orange.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminOrderScreen(initialStatus: 'pending'),
            ),
          ),
        ),
      if (lowStockProducts > 0)
        _AttentionRow(
          icon: Icons.inventory_2_outlined,
          title: 'Tồn kho thấp',
          detail: '$lowStockProducts sản phẩm còn dưới 5',
          color: Colors.red.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminProductScreen(initialLowStock: true),
            ),
          ),
        ),
    ];

    return Card(
      color: const Color(0xFFFFFBEB),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cần xử lý', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  const _AttentionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 4,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE3ED), Color(0xFFFFF4F8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD7E5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.analytics_outlined,
              size: 42, color: AppColors.pastelPinkDark),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thống kê quản trị',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pastelPinkDark,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Theo dõi doanh thu, đơn hàng và sản phẩm nổi bật của Tupi House',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.softPink,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(stat.icon, color: AppColors.pastelPinkDark),
            ),
            const SizedBox(height: 16),
            Text(
              stat.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              stat.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => module.screen),
        ),
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
                child: Icon(module.icon, color: AppColors.pastelPinkDark),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(
                      module.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 46, color: AppColors.pastelPink),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rank <= 3 ? AppColors.softPink : AppColors.softGreen,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color:
              rank <= 3 ? AppColors.pastelPinkDark : AppColors.pastelGreenDark,
        ),
      ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Không có quyền truy cập')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.redAccent),
              const SizedBox(height: 18),
              const Text(
                'Bạn không có quyền truy cập trang quản trị',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chỉ tài khoản Admin đang hoạt động mới được phép truy cập.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'confirmed':
      return Colors.blue;
    case 'shipping':
      return Colors.purple;
    case 'delivered':
      return AppColors.pastelGreenDark;
    case 'cancelled':
      return Colors.redAccent;
    default:
      return AppColors.muted;
  }
}

String _shortPeriodLabel(DateTime date, AnalyticsPeriod period) {
  switch (period) {
    case AnalyticsPeriod.day:
      return DateFormat('dd/MM').format(date);
    case AnalyticsPeriod.week:
      return 'T${_weekOfYear(date)}\n${DateFormat('dd/MM').format(date)}';
    case AnalyticsPeriod.month:
      return DateFormat('MM/yyyy').format(date);
  }
}

String _fullPeriodLabel(DateTime date, AnalyticsPeriod period) {
  switch (period) {
    case AnalyticsPeriod.day:
      return DateFormat('dd/MM/yyyy').format(date);
    case AnalyticsPeriod.week:
      final end = date.add(const Duration(days: 6));
      return '${DateFormat('dd/MM').format(date)} - '
          '${DateFormat('dd/MM/yyyy').format(end)}';
    case AnalyticsPeriod.month:
      return DateFormat('MM/yyyy').format(date);
  }
}

int _weekOfYear(DateTime date) {
  final firstDay = DateTime(date.year, 1, 1);
  final days = date.difference(firstDay).inDays + firstDay.weekday;
  return (days / 7).ceil();
}

String _compactMoney(double value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

class _Stat {
  final String title;
  final String value;
  final IconData icon;
  const _Stat(this.title, this.value, this.icon);
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
  const _Module(this.title, this.subtitle, this.icon, this.screen);
}
