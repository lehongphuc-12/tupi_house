import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của bạn'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(
                  color: Color(0xFFF0E8EB),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildProfileAvatar(
                      user.avatar,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLoyaltyCard(user.points, user.tier),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(
                  color: Color(0xFFF0E8EB),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.phone_outlined,
                      'Số điện thoại',
                      user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật',
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFFF6EFF1),
                    ),
                    _buildDetailRow(
                      Icons.face_outlined,
                      'Giới tính',
                      user.gender.isNotEmpty ? user.gender : 'Chưa cập nhật',
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xFFF6EFF1),
                    ),
                    _buildDetailRow(
                      Icons.cake_outlined,
                      'Ngày sinh',
                      user.birthday.isNotEmpty
                          ? user.birthday
                          : 'Chưa cập nhật',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionItem(
              icon: Icons.edit_outlined,
              title: 'Chỉnh sửa hồ sơ',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            // Hiển thị mục đổi mật khẩu cho cả Email/Password và Google Account
            _buildActionItem(
              icon: Icons.favorite_outline,
              title: 'Sản phẩm yêu thích',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WishlistScreen(),
                  ),
                );
              },
            ),
            if (authProvider.canChangePassword)
              _buildActionItem(
                icon: Icons.lock_outline_rounded,
                title: 'Đổi mật khẩu',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
            if (user.role == 'admin')
              _buildActionItem(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Quản trị hệ thống',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Theme(
                        data: AppTheme.adminTheme,
                        child: const AdminDashboardScreen(),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            _buildActionItem(
              icon: Icons.logout_rounded,
              title: 'Đăng xuất',
              danger: true,
              onTap: () async {
                await authProvider.logout();

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đăng xuất'),
                  ),
                );

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String avatar) {
    final avatarUrl = avatar.trim();

    return Container(
      width: 112,
      height: 112,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.softPink,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.isEmpty
          ? _buildDefaultAvatar()
          : Image.network(
              avatarUrl,
              key: ValueKey(avatarUrl),
              fit: BoxFit.cover,
              loadingBuilder: (
                context,
                child,
                loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorBuilder: (_, __, ___) {
                return _buildDefaultAvatar();
              },
            ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const ColoredBox(
      color: AppColors.softPink,
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 48,
          color: AppColors.pastelPinkDark,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.pastelGreenDark,
            size: 22,
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
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
    final textColor = danger ? Colors.redAccent : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        tileColor:
            danger ? Colors.red.withValues(alpha: 0.04) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: danger
                ? Colors.red.withValues(
                    alpha: 0.12,
                  )
                : const Color(0xFFF0E8EB),
          ),
        ),
        leading: Icon(
          icon,
          color: danger ? Colors.redAccent : AppColors.pastelPinkDark,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(int points, String tier) {
    Color tierColor;
    String nextTier = '';
    int nextTierPoints = 0;
    double progress = 0.0;
    String progressText = '';

    if (points >= 500) {
      tierColor = const Color(0xFF00E5FF); // Diamond Cyan
      nextTier = 'Tối đa';
      progress = 1.0;
      progressText = 'Bạn đã đạt hạng cao nhất!';
    } else if (points >= 200) {
      tierColor = const Color(0xFFFFD54F); // Gold
      nextTier = 'Kim Cương';
      nextTierPoints = 500 - points;
      progress = (points - 200) / 300.0;
      progressText = 'Còn $nextTierPoints điểm để thăng hạng $nextTier';
    } else if (points >= 50) {
      tierColor = const Color(0xFFB0BEC5); // Silver
      nextTier = 'Vàng';
      nextTierPoints = 200 - points;
      progress = (points - 50) / 150.0;
      progressText = 'Còn $nextTierPoints điểm để thăng hạng $nextTier';
    } else {
      tierColor = const Color(0xFF8D6E63); // Bronze
      nextTier = 'Bạc';
      nextTierPoints = 50 - points;
      progress = points / 50.0;
      progressText = 'Còn $nextTierPoints điểm để thăng hạng $nextTier';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFF0E8EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: AppColors.pastelPinkDark, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Tupi Loyalty',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tierColor, width: 1.5),
                  ),
                  child: Text(
                    'Hạng $tier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: tierColor == const Color(0xFFB0BEC5)
                          ? Colors.blueGrey[800]
                          : (tierColor == const Color(0xFFFFD54F)
                              ? Colors.orange[800]
                              : tierColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Điểm tích lũy:',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                Text(
                  '$points điểm',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pastelPinkDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.softPink,
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progressText,
              style: const TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
