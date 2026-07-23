import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.canChangePassword && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AuthProvider.googlePasswordManagedMessage)),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Xử lý đổi mật khẩu cho tài khoản Email/Password
  Future<void> _changePasswordForEmailAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công! 🎉')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Xử lý tạo mật khẩu cho tài khoản Google
  Future<void> _setupPasswordForGoogleAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.setupPasswordForGoogleAccount(
      password: _newPasswordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo mật khẩu thành công! 🎉\nBạn có thể đăng nhập bằng email/password.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    // Xác định loại tài khoản
    final isGoogleAccount = auth.isGoogleAccount;
    final hasPassword = auth.hasEmailPasswordProvider;
    final isGoogleWithoutPassword = isGoogleAccount && !hasPassword;

    return Scaffold(
      appBar: AppBar(
        title: Text(isGoogleWithoutPassword ? 'Tạo mật khẩu' : 'Đổi mật khẩu'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon thông báo
              Icon(
                isGoogleWithoutPassword ? Icons.lock_open : Icons.lock,
                size: 60,
                color: AppColors.pastelPinkDark,
              ),
              const SizedBox(height: 16),
              
              // Tiêu đề mô tả
              Text(
                isGoogleWithoutPassword
                    ? 'Tạo mật khẩu cho tài khoản Google'
                    : 'Nhập mật khẩu hiện tại và mật khẩu mới',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Chỉ hiển thị trường mật khẩu hiện tại cho tài khoản Email/Password
              if (!isGoogleWithoutPassword) ...[
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Vui lòng nhập mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Trường mật khẩu mới (dùng chung cho cả hai trường hợp)
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: isGoogleWithoutPassword ? 'Mật khẩu mới' : 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (v.length < 6) {
                    return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Trường xác nhận mật khẩu mới
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu mới';
                  }
                  if (v != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Nút xác nhận
              ElevatedButton(
                onPressed: _isLoading 
                    ? null 
                    : (isGoogleWithoutPassword 
                        ? _setupPasswordForGoogleAccount 
                        : _changePasswordForEmailAccount),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isGoogleWithoutPassword ? 'Tạo mật khẩu' : 'Cập nhật mật khẩu'),
              ),

              // Thông báo cho tài khoản Google
              if (isGoogleWithoutPassword) ...[
                const SizedBox(height: 16),
                const Text(
                  'Sau khi tạo mật khẩu, bạn có thể đăng nhập bằng:\n• Google\n• Email + Mật khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
