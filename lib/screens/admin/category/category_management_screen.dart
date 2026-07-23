import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/category.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/category/category_card.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final Set<String> _busyCategoryIds = <String>{};
  String _query = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final provider = context.read<AdminProvider>();
      await Future.wait([
        provider.loadCategories(),
        provider.loadProducts(),
      ]);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('Danh mục đang được sản phẩm sử dụng')) {
      return 'Danh mục đang được sản phẩm sử dụng nên chưa thể xóa.';
    }
    if (message.contains('permission-denied')) {
      return 'Tài khoản không có quyền thực hiện thao tác này.';
    }
    return 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
  }

  int _productCount(AdminProvider provider, String categoryId) {
    return provider.products
        .where((product) => product.categoryId == categoryId)
        .length;
  }

  Future<void> _saveCategory(Category? old) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: old?.name ?? '');
    final descriptionController =
        TextEditingController(text: old?.description ?? '');
    final imageController = TextEditingController(text: old?.image ?? '');
    final orderController =
        TextEditingController(text: (old?.order ?? 0).toString());
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate() || saving) return;
              setDialogState(() => saving = true);
              try {
                await this.context.read<AdminProvider>().saveCategory(
                      Category(
                        id: old?.id ?? '',
                        name: nameController.text,
                        image: imageController.text,
                        description: descriptionController.text,
                        order: int.tryParse(orderController.text.trim()) ?? 0,
                      ),
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  _showMessage(
                    old == null
                        ? 'Đã thêm danh mục.'
                        : 'Đã cập nhật danh mục.',
                  );
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(_friendlyError(error)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            }

            return PopScope(
              canPop: !saving,
              child: AlertDialog(
                insetPadding: const EdgeInsets.all(20),
                titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
                contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                title: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        old == null
                            ? Icons.add_rounded
                            : Icons.edit_outlined,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        old == null ? 'Thêm danh mục' : 'Chỉnh sửa danh mục',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: saving
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _DialogFieldLabel('Tên danh mục *'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: nameController,
                            autofocus: old == null,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Ví dụ: Decor phòng khách',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Vui lòng nhập tên danh mục'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          const _DialogFieldLabel('Mô tả'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: descriptionController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText:
                                  'Mô tả ngắn về phong cách hoặc sản phẩm trong danh mục',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _DialogFieldLabel('URL hình ảnh'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: imageController,
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'https://...',
                              prefixIcon: Icon(Icons.image_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _DialogFieldLabel('Thứ tự hiển thị'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: orderController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => submit(),
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixIcon: Icon(Icons.format_list_numbered),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              if (int.tryParse(value.trim()) == null) {
                                return 'Thứ tự phải là số nguyên';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Hủy'),
                  ),
                  FilledButton.icon(
                    onPressed: saving ? null : submit,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Đang lưu' : 'Lưu danh mục'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    orderController.dispose();
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa danh mục?'),
            content: Text(
              'Bạn có chắc muốn xóa “${category.name}”? Danh mục đang được sản phẩm sử dụng sẽ không thể xóa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _busyCategoryIds.add(category.id));
    try {
      await context.read<AdminProvider>().deleteCategory(category.id);
      if (mounted) _showMessage('Đã xóa danh mục.');
    } catch (error) {
      if (mounted) {
        _showMessage(_friendlyError(error), error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busyCategoryIds.remove(category.id));
      }
    }
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? AppColors.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) return const _AdminAccessDenied();

    final provider = context.watch<AdminProvider>();
    final normalizedQuery = _query.trim().toLowerCase();
    final categories = provider.categories.where((category) {
      if (normalizedQuery.isEmpty) return true;
      return '${category.name} ${category.description}'
          .toLowerCase()
          .contains(normalizedQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: MediaQuery.sizeOf(context).width < 720
          ? FloatingActionButton.extended(
              onPressed: () => _saveCategory(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm danh mục'),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primaryPink,
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.softPink, AppColors.lightCream],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final intro = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sắp xếp bộ sưu tập Tupi House',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '${provider.categories.length} danh mục · ${provider.products.length} sản phẩm',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              );
                              if (constraints.maxWidth < 700) return intro;
                              return Row(
                                children: [
                                  Expanded(child: intro),
                                  FilledButton.icon(
                                    onPressed: () => _saveCategory(null),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Thêm danh mục'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên hoặc mô tả danh mục',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Xóa tìm kiếm',
                                    onPressed: () => setState(() => _query = ''),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading && provider.categories.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPink,
                  ),
                ),
              )
            else if (_errorMessage != null && provider.categories.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _AdminCategoryMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Không thể tải danh mục',
                  description: _errorMessage!,
                  actionLabel: 'Thử lại',
                  onPressed: _loadData,
                ),
              )
            else if (categories.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _AdminCategoryMessage(
                  icon: _query.isEmpty
                      ? Icons.category_outlined
                      : Icons.search_off_rounded,
                  title: _query.isEmpty
                      ? 'Chưa có danh mục'
                      : 'Không tìm thấy danh mục phù hợp',
                  description: _query.isEmpty
                      ? 'Tạo danh mục đầu tiên để tổ chức sản phẩm trong cửa hàng.'
                      : 'Hãy thử một từ khóa khác hoặc xóa nội dung tìm kiếm.',
                  actionLabel: _query.isEmpty ? 'Thêm danh mục' : 'Xóa tìm kiếm',
                  onPressed: () async {
                    if (_query.isEmpty) {
                      await _saveCategory(null);
                    } else if (mounted) {
                      setState(() => _query = '');
                    }
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) => SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360,
                      mainAxisExtent: 330,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = categories[index];
                        return AdminCategoryCard(
                          category: category,
                          productCount: _productCount(provider, category.id),
                          isBusy: _busyCategoryIds.contains(category.id),
                          onEdit: () => _saveCategory(category),
                          onDelete: () => _deleteCategory(category),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogFieldLabel extends StatelessWidget {
  final String text;

  const _DialogFieldLabel(this.text);

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

class _AdminCategoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onPressed;

  const _AdminCategoryMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: const BoxDecoration(
                  color: AppColors.softPink,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 50, color: AppColors.primaryPink),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => onPressed(),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAccessDenied extends StatelessWidget {
  const _AdminAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không có quyền truy cập')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: AppColors.muted,
              ),
              SizedBox(height: 18),
              Text(
                'Bạn không có quyền truy cập chức năng quản trị.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
