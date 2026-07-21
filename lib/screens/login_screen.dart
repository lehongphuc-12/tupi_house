import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'admin/admin_dashboard_screen.dart';
import 'product/optimized_product_list_screen.dart';
import 'register_screen.dart';  

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();

    final auth = context.read<AuthProvider>();

    if (auth.rememberMe && auth.savedEmail != null) {
      _emailController.text = auth.savedEmail!;
      _rememberMe = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateAfterLogin(AuthProvider auth) {
    final Widget destination;

    if (auth.isAdmin) {
      destination = const AdminDashboardScreen();
    } else {
      destination = const OptimizedProductListScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => destination,
      ),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();

    final ok = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      remember: _rememberMe,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      _navigateAfterLogin(auth);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Đăng nhập thất bại',
          ),
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthProvider>();

    final ok = await auth.loginWithGoogle();

    if (!mounted) {
      return;
    }

    if (ok) {
      _navigateAfterLogin(auth);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Đăng nhập Google thất bại',
          ),
        ),
      );
    }
  }

  Widget _brand({required bool wide}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.softPink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Image.asset(
            'assets/logo.png',
            width: wide ? 190 : 145,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tupi House',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Quản lý sản phẩm và giỏ hàng gọn gàng, hiện đại.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _loginForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Đăng nhập',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhập thông tin tài khoản đã đăng ký.',
            style: TextStyle(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }

              final regex = RegExp(
                r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$',
              );

              if (!regex.hasMatch(value.trim())) {
                return 'Email không hợp lệ';
              }

              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!auth.isLoading) {
                _submit();
              }
            },
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }

              return null;
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                activeColor: AppColors.pastelGreenDark,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              const Flexible(
                child: Text('Ghi nhớ đăng nhập'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Đăng nhập'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
            child: const Text(
              'Chưa có tài khoản? Đăng ký ngay',
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: Divider(
                  color: Color(0xFFE0E0E0),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'HOẶC',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              side: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: auth.isLoading
                ? null
                : () async {
                    final ok = await auth.loginWithGoogle();
                    if (!mounted) return;
                    if (ok) {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => const OptimizedProductListScreen()));
                    } else if (auth.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(auth.errorMessage!)));
                    }
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.g_mobiledata,
                      color: Colors.blue,
                    );
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Đăng nhập bằng Google',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 18,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 920 : 460,
                  ),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        isWide ? 34 : 22,
                      ),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _brand(wide: true),
                                ),
                                const SizedBox(width: 34),
                                Expanded(
                                  child: _loginForm(auth),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _brand(wide: false),
                                const SizedBox(height: 26),
                                _loginForm(auth),
                              ],
                            ),
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
