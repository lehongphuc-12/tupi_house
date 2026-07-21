import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../wishlist/wishlist_screen.dart';
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
        title: const Text('Trang cá nhân'),
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
            const SizedBox(height: 20),
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
            _buildActionItem(
              icon: Icons.favorite_border_rounded,
              title: 'Danh sách yêu thích',
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
}
