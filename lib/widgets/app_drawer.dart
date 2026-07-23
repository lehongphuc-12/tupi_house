import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _open(BuildContext context, Widget destination, {bool replace = false}) {
    Navigator.of(context).pop();
    final route = MaterialPageRoute(builder: (_) => destination);
    if (replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  void _openProtected(
    BuildContext context,
    AuthProvider auth,
    Widget destination,
  ) {
    _open(
      context,
      auth.isLoggedIn ? destination : const LoginScreen(returnToPrevious: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final unread = auth.isLoggedIn
        ? context.watch<NotificationProvider>().unreadCount
        : 0;
    final user = auth.currentUser;
    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Khách của Tupi House';
    final email = user?.email ?? 'Đăng nhập để lưu sản phẩm yêu thích';
    final avatar = user?.avatar.trim() ?? '';

    return Drawer(
      width: 330,
      backgroundColor: AppColors.warmWhite,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(26),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.softPink, AppColors.softGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white),
                  ),
                  child: InkWell(
                    onTap: () => _openProtected(
                      context,
                      auth,
                      const ProfileScreen(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: avatar.isNotEmpty
                                      ? Image.network(
                                          avatar,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                            'assets/logo.png',
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/logo.png',
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                children: [
                  const _DrawerSectionLabel('Mua sắm'),
                  _DrawerItem(
                    icon: Icons.storefront_outlined,
                    title: 'Danh sách sản phẩm',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Giỏ hàng',
                    onTap: () =>
                        _openProtected(context, auth, const CartScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Đơn hàng của tôi',
                    onTap: () => _openProtected(
                      context,
                      auth,
                      const OrderHistoryScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Sản phẩm yêu thích',
                    onTap: () => _openProtected(
                      context,
                      auth,
                      const WishlistScreen(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _DrawerSectionLabel('Tài khoản'),
                  _DrawerItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Thông báo',
                    badge: unread > 0 ? '$unread' : null,
                    onTap: () => _openProtected(
                      context,
                      auth,
                      const NotificationsScreen(),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Trang cá nhân',
                    onTap: () => _openProtected(
                      context,
                      auth,
                      const ProfileScreen(),
                    ),
                  ),
                  if (auth.isAdmin) ...[
                    const SizedBox(height: 10),
                    const _DrawerSectionLabel('Quản trị'),
                    _DrawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin Dashboard',
                      accent: AppColors.sageGreenDark,
                      onTap: () => _open(
                        context,
                        const AdminDashboardScreen(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
              child: auth.isLoggedIn
                  ? _DrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Đăng xuất',
                      danger: true,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã đăng xuất.')),
                        );
                      },
                    )
                  : _DrawerItem(
                      icon: Icons.login_rounded,
                      title: 'Đăng nhập',
                      onTap: () => _open(context, const LoginScreen()),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String text;

  const _DrawerSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final String? badge;
  final Color? accent;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.badge,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : (accent ?? AppColors.textPrimary);
    final iconBackground = danger
        ? AppColors.errorLight
        : accent != null
            ? AppColors.softGreen
            : AppColors.softPink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    constraints: const BoxConstraints(minWidth: 26),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badge!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted.withValues(alpha: 0.65),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
