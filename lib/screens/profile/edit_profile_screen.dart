import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/default_avatars.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _avatarFocusNode = FocusNode();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  String _selectedGender = 'Khác';
  String? _selectedPresetAvatar;
  DateTime? _selectedBirthday;

  bool _isSaving = false;
  bool _avatarLoadFailed = false;
  bool _avatarIsLoading = false;

  String get _avatarUrl => _avatarController.text.trim();

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().currentUser;

    _nameController = TextEditingController(
      text: user?.fullName ?? '',
    );

    _phoneController = TextEditingController(
      text: user?.phone ?? '',
    );

    _avatarController = TextEditingController(
      text: user?.avatar.trim() ?? '',
    );

    if (_avatarUrl.isNotEmpty && _isValidImageUrl(_avatarUrl)) {
      _avatarIsLoading = true;
    }

    if (DefaultAvatars.avatars.contains(_avatarUrl)) {
      _selectedPresetAvatar = _avatarUrl;
    }

    if (user != null &&
        user.gender.isNotEmpty &&
        const ['Nam', 'Nữ', 'Khác'].contains(user.gender)) {
      _selectedGender = user.gender;
    }

    if (user != null && user.birthday.isNotEmpty) {
      try {
        _selectedBirthday = DateFormat(
          'dd/MM/yyyy',
        ).parseStrict(user.birthday);
      } catch (_) {
        _selectedBirthday = null;
      }
    }

    _avatarFocusNode.addListener(_handleAvatarFocusChange);
  }

  @override
  void dispose() {
    _avatarFocusNode
      ..removeListener(_handleAvatarFocusChange)
      ..dispose();

    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();

    super.dispose();
  }

  void _handleAvatarFocusChange() {
    if (!_avatarFocusNode.hasFocus) {
      _trimAvatarUrl();
    }
  }

  void _trimAvatarUrl() {
    final trimmedUrl = _avatarController.text.trim();

    if (_avatarController.text == trimmedUrl) {
      return;
    }

    _avatarController.value = TextEditingValue(
      text: trimmedUrl,
      selection: TextSelection.collapsed(
        offset: trimmedUrl.length,
      ),
    );
  }

  bool _isValidImageUrl(String value) {
    final url = value.trim();

    // Cho phép người dùng không sử dụng avatar.
    if (url.isEmpty) {
      return true;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      return false;
    }

    return uri.hasScheme &&
        uri.hasAuthority &&
        const ['http', 'https'].contains(
          uri.scheme.toLowerCase(),
        );
  }

  void _onAvatarChanged(String value) {
    final trimmedUrl = value.trim();
    final validUrl = _isValidImageUrl(trimmedUrl);

    setState(() {
      _selectedPresetAvatar =
          DefaultAvatars.avatars.contains(trimmedUrl) ? trimmedUrl : null;

      _avatarLoadFailed = false;
      _avatarIsLoading = trimmedUrl.isNotEmpty && validUrl;
    });
  }

  void _selectPresetAvatar(String avatarUrl) {
    _avatarController.value = TextEditingValue(
      text: avatarUrl,
      selection: TextSelection.collapsed(
        offset: avatarUrl.length,
      ),
    );

    setState(() {
      _selectedPresetAvatar = avatarUrl;
      _avatarLoadFailed = false;
      _avatarIsLoading = true;
    });

    _formKey.currentState?.validate();
  }

  void _reportAvatarLoadSuccess(String loadedUrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _avatarUrl != loadedUrl) {
        return;
      }

      if (!_avatarIsLoading && !_avatarLoadFailed) {
        return;
      }

      setState(() {
        _avatarIsLoading = false;
        _avatarLoadFailed = false;
      });
    });
  }

  void _reportAvatarLoadFailure(String failedUrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _avatarUrl != failedUrl) {
        return;
      }

      if (_avatarLoadFailed && !_avatarIsLoading) {
        return;
      }

      setState(() {
        _avatarIsLoading = false;
        _avatarLoadFailed = true;
      });
    });
  }

  Future<void> _selectBirthday() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || pickedDate == _selectedBirthday) {
      return;
    }

    setState(() {
      _selectedBirthday = pickedDate;
    });
  }

  Future<void> _save() async {
    _avatarFocusNode.unfocus();
    _trimAvatarUrl();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final avatar = _avatarUrl;

    if (avatar.isNotEmpty && _avatarIsLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ảnh đang được tải. Vui lòng chờ trong giây lát.',
          ),
        ),
      );

      return;
    }

    if (avatar.isNotEmpty && _avatarLoadFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể tải ảnh từ đường dẫn này.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authProvider = context.read<AuthProvider>();

    final birthday = _selectedBirthday == null
        ? ''
        : DateFormat(
            'dd/MM/yyyy',
          ).format(_selectedBirthday!);

    try {
      final success = await authProvider.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender,
        birthday: birthday,
        avatar: avatar,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cập nhật hồ sơ thành công! 🎉',
            ),
          ),
        );

        Navigator.of(context).pop();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Cập nhật hồ sơ thất bại.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã xảy ra lỗi khi cập nhật hồ sơ.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final birthdayDisplay = _selectedBirthday == null
        ? 'Chọn ngày sinh'
        : DateFormat(
            'dd/MM/yyyy',
          ).format(_selectedBirthday!);

    final isBusy = authProvider.isLoading || _isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }

                    if (!RegExp(r'^[0-9]{9,11}$').hasMatch(phone)) {
                      return 'Số điện thoại không hợp lệ (9 - 11 chữ số)';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    prefixIcon: Icon(
                      Icons.face_outlined,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Nam',
                      child: Text('Nam'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Nữ',
                      child: Text('Nữ'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Khác',
                      child: Text('Khác'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectBirthday,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh',
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          birthdayDisplay,
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedBirthday == null
                                ? AppColors.muted
                                : AppColors.ink,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: AppColors.pastelPinkDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isBusy ? null : _save,
                  child: isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lưu thay đổi'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final avatarUrl = _avatarUrl;
    final validUrl = _isValidImageUrl(avatarUrl);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _buildAvatarPreview(
                avatarUrl: avatarUrl,
                validUrl: validUrl,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _avatarController,
              focusNode: _avatarFocusNode,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Ảnh đại diện (URL)',
                hintText: 'https://example.com/avatar',
                prefixIcon: Icon(
                  Icons.image_outlined,
                ),
              ),
              onChanged: _onAvatarChanged,
              onFieldSubmitted: (_) {
                _trimAvatarUrl();
              },
              validator: (value) {
                if (!_isValidImageUrl(value ?? '')) {
                  return 'Đường dẫn ảnh không hợp lệ.';
                }

                return null;
              },
            ),
            if (_avatarLoadFailed) ...[
              const SizedBox(height: 8),
              const Text(
                'Không thể tải ảnh từ đường dẫn này.',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
            if (_avatarIsLoading && avatarUrl.isNotEmpty && validUrl) ...[
              const SizedBox(height: 8),
              const Text(
                'Đang kiểm tra ảnh...',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(
                  child: Divider(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Text(
                    'HOẶC',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn ảnh đại diện có sẵn',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DefaultAvatars.avatars.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(width: 10);
                },
                itemBuilder: (context, index) {
                  final presetUrl = DefaultAvatars.avatars[index];
                  final isSelected = presetUrl == _selectedPresetAvatar;

                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Avatar mẫu ${index + 1}',
                    child: InkWell(
                      onTap: () {
                        _selectPresetAvatar(presetUrl);
                      },
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.pastelPinkDark
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.pastelPinkDark
                                : const Color(0xFFE8E2E5),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 31,
                          backgroundColor: AppColors.softPink,
                          child: ClipOval(
                            child: Image.network(
                              presetUrl,
                              width: 62,
                              height: 62,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const SizedBox(
                                  width: 62,
                                  height: 62,
                                  child: ColoredBox(
                                    color: AppColors.softPink,
                                    child: Icon(
                                      Icons.person_outline,
                                      color: AppColors.pastelPinkDark,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview({
    required String avatarUrl,
    required bool validUrl,
  }) {
    return Container(
      width: 124,
      height: 124,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.softPink,
      ),
      child: ClipOval(
        child: avatarUrl.isEmpty || !validUrl
            ? _buildDefaultAvatarPreview()
            : Image.network(
                avatarUrl,
                key: ValueKey<String>(avatarUrl),
                width: 114,
                height: 114,
                fit: BoxFit.cover,
                // Sử dụng cacheWidth và cacheHeight để tối ưu hiệu năng trên Web
                cacheWidth: 228,
                cacheHeight: 228,
                frameBuilder: (
                  context,
                  child,
                  frame,
                  wasSynchronouslyLoaded,
                ) {
                  // Nếu tải đồng bộ hoặc đã có frame -> thành công
                  if (wasSynchronouslyLoaded || frame != null) {
                    _reportAvatarLoadSuccess(avatarUrl);
                  }

                  return child;
                },
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  // Nếu chưa bắt đầu tải hoặc đã tải xong -> hiển thị ảnh
                  if (loadingProgress == null) {
                    return child;
                  }

                  // Đang tải -> hiển thị progress
                  return SizedBox(
                    width: 114,
                    height: 114,
                    child: ColoredBox(
                      color: AppColors.softPink,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // Báo lỗi khi tải ảnh thất bại
                  _reportAvatarLoadFailure(avatarUrl);

                  return const SizedBox(
                    width: 114,
                    height: 114,
                    child: ColoredBox(
                      color: AppColors.softPink,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 46,
                        color: AppColors.pastelPinkDark,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDefaultAvatarPreview() {
    return const SizedBox(
      width: 114,
      height: 114,
      child: ColoredBox(
        color: AppColors.softPink,
        child: Icon(
          Icons.person_outline,
          size: 54,
          color: AppColors.pastelPinkDark,
        ),
      ),
    );
  }
}
