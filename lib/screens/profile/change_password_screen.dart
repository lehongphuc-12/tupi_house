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
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.canChangePassword && !auth.needsPasswordSetup) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AuthProvider.googlePasswordManagedMessage),
          ),
        );
        Navigator.of(context).maybePop();
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

  void _clearPasswords() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _changePasswordForEmailAccount() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    final error = await context.read<AuthProvider>().changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;

    if (error == null) {
      _clearPasswords();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công.')),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: AppColors.error),
    );
  }

  Future<void> _setupPasswordForGoogleAccount() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    final error = await context.read<AuthProvider>().setupPasswordForGoogleAccount(
          password: _newPasswordController.text,
        );
    if (!mounted) return;

    if (error == null) {
      _clearPasswords();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tạo mật khẩu thành công. Bạn có thể đăng nhập bằng Google hoặc email.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGoogleWithoutPassword = auth.needsPasswordSetup;
    final title = isGoogleWithoutPassword ? 'Tạo mật khẩu' : 'Đổi mật khẩu';

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth < 600 ? 20 : 32,
                24,
                constraints.maxWidth < 600 ? 20 : 32,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SecurityHeader(
                          title: isGoogleWithoutPassword
                              ? 'Thiết lập thêm một cách đăng nhập'
                              : 'Bảo vệ tài khoản của bạn',
                          description: isGoogleWithoutPassword
                              ? 'Tạo mật khẩu để có thể đăng nhập bằng email khi cần. Tài khoản Google của bạn vẫn được giữ nguyên.'
                              : 'Sử dụng mật khẩu mới từ 6 ký tự trở lên và không chia sẻ mật khẩu với người khác.',
                          icon: isGoogleWithoutPassword
                              ? Icons.add_moderator_outlined
                              : Icons.lock_reset_rounded,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(
                            constraints.maxWidth < 600 ? 20 : 28,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.outlineSoft),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isGoogleWithoutPassword) ...[
                                const _FieldLabel('Mật khẩu hiện tại'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: _obscureCurrent,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    hintText: 'Nhập mật khẩu hiện tại',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      tooltip: _obscureCurrent
                                          ? 'Hiện mật khẩu'
                                          : 'Ẩn mật khẩu',
                                      onPressed: () => setState(
                                        () => _obscureCurrent = !_obscureCurrent,
                                      ),
                                      icon: Icon(
                                        _obscureCurrent
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu hiện tại';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                              const _FieldLabel('Mật khẩu mới'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscureNew,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.newPassword],
                                decoration: InputDecoration(
                                  hintText: 'Tối thiểu 6 ký tự',
                                  prefixIcon:
                                      const Icon(Icons.key_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureNew
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                    onPressed: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                    icon: Icon(
                                      _obscureNew
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu mới';
                                  }
                                  if (value.length < 6) {
                                    return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              const _FieldLabel('Xác nhận mật khẩu mới'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.newPassword],
                                onFieldSubmitted: (_) {
                                  if (isGoogleWithoutPassword) {
                                    _setupPasswordForGoogleAccount();
                                  } else {
                                    _changePasswordForEmailAccount();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Nhập lại mật khẩu mới',
                                  prefixIcon:
                                      const Icon(Icons.verified_user_outlined),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirm
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng xác nhận mật khẩu mới';
                                  }
                                  if (value != _newPasswordController.text) {
                                    return 'Mật khẩu xác nhận không khớp';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 18,
                                    color: AppColors.sageGreenDark,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Mật khẩu được gửi trực tiếp đến Firebase Authentication và không được lưu trong ứng dụng.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.45,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              FilledButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : isGoogleWithoutPassword
                                        ? _setupPasswordForGoogleAccount
                                        : _changePasswordForEmailAccount,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 19,
                                        height: 19,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.lock_rounded),
                                label: Text(
                                  isGoogleWithoutPassword
                                      ? 'Tạo mật khẩu'
                                      : 'Cập nhật mật khẩu',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SecurityHeader extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _SecurityHeader({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.softPink, AppColors.softGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 44, color: AppColors.primaryPink),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
