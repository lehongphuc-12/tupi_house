import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.pastelGreenDark),
              SizedBox(width: 8),
              Text('Thành công'),
            ],
          ),
          content: const Text(
            'Email đặt lại mật khẩu đã được gửi.\nVui lòng kiểm tra hộp thư.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email này không tồn tại trong hệ thống.';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ.';
          break;
        case 'too-many-requests':
          errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
          break;
        case 'network-request-failed':
          errorMessage = 'Lỗi mạng. Vui lòng kiểm tra kết nối internet.';
          break;
        default:
          errorMessage = e.message ?? 'Đã xảy ra lỗi. Vui lòng thử lại.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xảy ra lỗi. Vui lòng thử lại.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Icon
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppColors.pastelPinkDark,
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Khôi phục mật khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nhập địa chỉ email bạn đã sử dụng để đăng ký. Chúng tôi sẽ gửi cho bạn một liên kết để đặt lại mật khẩu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'Nhập email của bạn',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
                    if (!regex.hasMatch(v.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _sendPasswordResetEmail(),
                ),
                const SizedBox(height: 24),
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendPasswordResetEmail,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Gửi email đặt lại mật khẩu'),
                ),
                const SizedBox(height: 16),
                // Back to login
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Quay lại đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
