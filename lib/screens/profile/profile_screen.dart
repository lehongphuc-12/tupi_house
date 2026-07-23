import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../orders/order_history_screen.dart';
import '../notifications/notifications_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onNavigateHome});

  final VoidCallback? onNavigateHome;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();

      if (!authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.warmWhite, AppColors.softPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.outlineSoft),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileAvatar(user.avatar),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Chỉnh sửa hồ sơ'),
                      ),
                      const SizedBox(height: 8),
                      _buildLoyaltyCard(user.points, user.tier),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Số điện thoại',
                        user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildInfoRow(
                        Icons.wc_outlined,
                        'Giới tính',
                        user.gender.isNotEmpty ? user.gender : 'Chưa cập nhật',
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildInfoRow(
                        Icons.cake_outlined,
                        'Ngày sinh',
                        user.birthday.isNotEmpty
                            ? user.birthday
                            : 'Chưa cập nhật',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _buildSectionLabel('Mua sắm'),
                _buildActionItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Đơn hàng của tôi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  ),
                ),
                _buildActionItem(
                  icon: Icons.favorite_outline,
                  title: 'Sản phẩm yêu thích',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WishlistScreen(
                        onExploreHome: widget.onNavigateHome,
                      ),
                    ),
                  ),
                ),
                _buildActionItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Thông báo',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildSectionLabel('Tài khoản'),
                _buildActionItem(
                  icon: Icons.person_outline,
                  title: 'Chỉnh sửa hồ sơ',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                ),
                if (authProvider.canChangePassword)
                  _buildActionItem(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                if (user.role == 'admin') ...[
                  const SizedBox(height: 14),
                  _buildSectionLabel('Quản trị'),
                  _buildActionItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Quản trị hệ thống',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Theme(
                          data: AppTheme.adminTheme,
                          child: const AdminDashboardScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _buildActionItem(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  danger: true,
                  onTap: () async {
                    await authProvider.logout();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đăng xuất')),
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String avatar) {
    final avatarUrl = avatar.trim();

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.softPink,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.isEmpty
          ? _buildDefaultAvatar()
          : Image.network(
              avatarUrl,
              key: ValueKey(avatarUrl),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPink,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
            ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.softPink,
      child: const Center(
        child: Icon(
          Icons.person_outline,
          size: 44,
          color: AppColors.primaryPink,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.softPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: danger ? AppColors.error.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: danger
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: danger
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.softPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: danger ? AppColors.error : AppColors.primaryPink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: danger ? AppColors.error : AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: danger ? AppColors.error : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(int points, String tier) {
    Color tierColor;
    double progress = 0.0;

    if (points >= 500) {
      tierColor = AppColors.deepSage; // Kim Cương
      progress = 1.0;
    } else if (points >= 200) {
      tierColor = AppColors.warning; // Vàng
      progress = (points - 200) / 300.0;
    } else if (points >= 50) {
      tierColor = AppColors.muted; // Bạc
      progress = (points - 50) / 150.0;
    } else {
      tierColor = AppColors.woodBrown; // Đồng
      progress = points / 50.0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.stars, color: tierColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hạng $tier',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: tierColor,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$points điểm',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPink,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
