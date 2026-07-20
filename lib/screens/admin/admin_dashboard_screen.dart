import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFC),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFAFC),
        surfaceTintColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 1000 ? 32.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(),
                    SizedBox(height: 24),
                    _StatisticsSection(),
                    SizedBox(height: 32),
                    _ManagementSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
          colors: [
            Color(0xFFFFE3ED),
            Color(0xFFFFF3F7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD7E5),
        ),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              size: 32,
              color: AppColors.pastelPinkDark,
            ),
          ),
          const Column(
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
              SizedBox(height: 6),
              Text(
                'Theo dõi và quản lý hoạt động của Tupi House',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Tổng quan',
          subtitle: 'Dữ liệu thống kê của hệ thống',
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: _statistics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisExtent: 150,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final item = _statistics[index];

            return _StatisticCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              iconBackground: item.iconBackground,
              iconColor: item.iconColor,
            );
          },
        ),
      ],
    );
  }
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Quản lý',
          subtitle: 'Chọn chức năng quản trị',
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: _managementItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            mainAxisExtent: 150,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final item = _managementItems[index];

            return _ManagementCard(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Chức năng ${item.title} sẽ được phát triển tiếp theo.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEEE7EA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEEE7EA),
            ),
          ),
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
                  icon,
                  color: AppColors.pastelPinkDark,
                  size: 27,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticData {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _StatisticData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _ManagementData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ManagementData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const List<_StatisticData> _statistics = [
  _StatisticData(
    title: 'Sản phẩm',
    value: '--',
    icon: Icons.inventory_2_outlined,
    iconBackground: Color(0xFFFFE8EF),
    iconColor: Color(0xFFD96088),
  ),
  _StatisticData(
    title: 'Người dùng',
    value: '--',
    icon: Icons.people_outline,
    iconBackground: Color(0xFFE8F1FF),
    iconColor: Color(0xFF527DCA),
  ),
  _StatisticData(
    title: 'Đơn hàng',
    value: '--',
    icon: Icons.receipt_long_outlined,
    iconBackground: Color(0xFFFFF1DE),
    iconColor: Color(0xFFD78A25),
  ),
  _StatisticData(
    title: 'Doanh thu',
    value: '-- ₫',
    icon: Icons.payments_outlined,
    iconBackground: Color(0xFFE5F7EE),
    iconColor: Color(0xFF3B9B70),
  ),
];

const List<_ManagementData> _managementItems = [
  _ManagementData(
    title: 'Sản phẩm',
    subtitle: 'Thêm, sửa, xóa và quản lý sản phẩm',
    icon: Icons.inventory_2_outlined,
  ),
  _ManagementData(
    title: 'Danh mục',
    subtitle: 'Quản lý các danh mục sản phẩm',
    icon: Icons.category_outlined,
  ),
  _ManagementData(
    title: 'Đơn hàng',
    subtitle: 'Theo dõi và cập nhật trạng thái đơn hàng',
    icon: Icons.receipt_long_outlined,
  ),
  _ManagementData(
    title: 'Người dùng',
    subtitle: 'Xem và quản lý tài khoản người dùng',
    icon: Icons.people_outline,
  ),
  _ManagementData(
    title: 'Voucher',
    subtitle: 'Tạo và quản lý các mã giảm giá',
    icon: Icons.local_offer_outlined,
  ),
  _ManagementData(
    title: 'Thống kê',
    subtitle: 'Theo dõi doanh thu và hoạt động bán hàng',
    icon: Icons.bar_chart_outlined,
  ),
];
