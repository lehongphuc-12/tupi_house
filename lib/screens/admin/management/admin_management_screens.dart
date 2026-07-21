import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../orders/order_detail_screen.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../models/user.dart';
import '../../../models/voucher.dart';
import '../../../providers/admin_provider.dart';
import '../../../theme/app_theme.dart';

final _money =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});
  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  String query = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AdminProvider>().loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final items = provider.categories
        .where((e) => '${e.name} ${e.description}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    return _AdminScaffold(
      title: 'Quản lý danh mục',
      actionLabel: 'Thêm danh mục',
      onAdd: () => _showCategoryDialog(context),
      onRefresh: provider.loadCategories,
      searchHint: 'Tìm tên hoặc mô tả danh mục',
      onSearch: (value) => setState(() => query = value),
      child: _loadingOrEmpty(provider, items, 'Chưa có danh mục',
          () => _categoryGrid(context, items)),
    );
  }

  Widget _categoryGrid(BuildContext context, List<Category> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisExtent: 220,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16),
      itemBuilder: (_, index) {
        final item = items[index];
        return _AdminCard(
          icon: Icons.category_outlined,
          title: item.name,
          subtitle:
              item.description.isEmpty ? 'Chưa có mô tả' : item.description,
          badge: 'Thứ tự ${item.order}',
          imageUrl: item.image,
          onEdit: () => _showCategoryDialog(context, item),
          onDelete: () => _confirm(context, 'Xóa danh mục "${item.name}"?',
              () => context.read<AdminProvider>().deleteCategory(item.id)),
        );
      },
    );
  }
}

Future<void> _showCategoryDialog(BuildContext context, [Category? old]) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: old?.name ?? '');
  final description = TextEditingController(text: old?.description ?? '');
  final image = TextEditingController(text: old?.image ?? '');
  final order = TextEditingController(text: '${old?.order ?? 0}');
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(old == null ? 'Thêm danh mục' : 'Sửa danh mục'),
      content: SizedBox(
          width: 520,
          child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Tên danh mục *'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập tên'
                        : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                    maxLines: 2),
                const SizedBox(height: 12),
                TextFormField(
                    controller: image,
                    decoration:
                        const InputDecoration(labelText: 'URL hình ảnh')),
                const SizedBox(height: 12),
                TextFormField(
                    controller: order,
                    decoration:
                        const InputDecoration(labelText: 'Thứ tự hiển thị'),
                    keyboardType: TextInputType.number),
              ]))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy')),
        FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await context.read<AdminProvider>().saveCategory(Category(
                    id: old?.id ?? '',
                    name: name.text,
                    image: image.text,
                    description: description.text,
                    order: int.tryParse(order.text) ?? 0));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) _message(context, 'Đã lưu danh mục');
              } catch (e) {
                if (context.mounted) _message(context, '$e', error: true);
              }
            },
            child: const Text('Lưu')),
      ],
    ),
  );
}

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});
  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  String query = '';
  String categoryId = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<AdminProvider>();
      await Future.wait([p.loadProducts(), p.loadCategories()]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final items = provider.products.where((e) {
      final searchOk = '${e.title} ${e.categoryName}'
          .toLowerCase()
          .contains(query.toLowerCase());
      return searchOk && (categoryId.isEmpty || e.categoryId == categoryId);
    }).toList();
    return _AdminScaffold(
      title: 'Quản lý sản phẩm',
      actionLabel: 'Thêm sản phẩm',
      onAdd: () => _showProductDialog(context),
      onRefresh: provider.loadProducts,
      searchHint: 'Tìm tên hoặc danh mục sản phẩm',
      onSearch: (value) => setState(() => query = value),
      extraFilter: DropdownButtonFormField<String>(
        value: categoryId,
        decoration: const InputDecoration(labelText: 'Danh mục'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Tất cả danh mục')),
          ...provider.categories
              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
        ],
        onChanged: (value) => setState(() => categoryId = value ?? ''),
      ),
      child: _loadingOrEmpty(
          provider,
          items,
          'Chưa có sản phẩm',
          () => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 245,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return _AdminCard(
                    icon: Icons.inventory_2_outlined,
                    title: item.title,
                    subtitle: '${item.categoryName} • Kho ${item.stock}',
                    badge: _money.format(item.salePrice ?? item.price),
                    imageUrl: item.thumbnail,
                    onEdit: () => _showProductDialog(context, item),
                    onDelete: () => _confirm(
                        context,
                        'Xóa sản phẩm "${item.title}"?',
                        () => context
                            .read<AdminProvider>()
                            .deleteProduct(item.id)),
                  );
                },
              )),
    );
  }
}

Future<void> _showProductDialog(BuildContext context, [Product? old]) async {
  final provider = context.read<AdminProvider>();
  if (provider.categories.isEmpty) await provider.loadCategories();
  if (!context.mounted) return;
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController(text: old?.title ?? '');
  final price = TextEditingController(text: '${old?.price ?? ''}');
  final salePrice =
      TextEditingController(text: old?.salePrice?.toString() ?? '');
  final stock = TextEditingController(text: '${old?.stock ?? 0}');
  final image = TextEditingController(text: old?.thumbnail ?? '');
  final description = TextEditingController(text: old?.description ?? '');
  String selectedCategory = old?.categoryId ??
      (provider.categories.isEmpty ? '' : provider.categories.first.id);
  await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
                title: Text(old == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
                content: SizedBox(
                    width: 620,
                    child: SingleChildScrollView(
                        child: Form(
                            key: formKey,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                      controller: title,
                                      decoration: const InputDecoration(
                                          labelText: 'Tên sản phẩm *'),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Vui lòng nhập tên'
                                              : null),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                      value: selectedCategory.isEmpty
                                          ? null
                                          : selectedCategory,
                                      decoration: const InputDecoration(
                                          labelText: 'Danh mục *'),
                                      items: provider.categories
                                          .map((e) => DropdownMenuItem(
                                              value: e.id, child: Text(e.name)))
                                          .toList(),
                                      onChanged: (v) => setDialogState(
                                          () => selectedCategory = v ?? '')),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    Expanded(
                                        child: TextFormField(
                                            controller: price,
                                            decoration: const InputDecoration(
                                                labelText: 'Giá *'),
                                            keyboardType: TextInputType.number,
                                            validator: (v) =>
                                                int.tryParse(v ?? '') == null
                                                    ? 'Giá không hợp lệ'
                                                    : null)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: TextFormField(
                                            controller: salePrice,
                                            decoration: const InputDecoration(
                                                labelText: 'Giá khuyến mãi'),
                                            keyboardType: TextInputType.number))
                                  ]),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                      controller: stock,
                                      decoration: const InputDecoration(
                                          labelText: 'Tồn kho'),
                                      keyboardType: TextInputType.number),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                      controller: image,
                                      decoration: const InputDecoration(
                                          labelText: 'URL hình ảnh')),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                      controller: description,
                                      decoration: const InputDecoration(
                                          labelText: 'Mô tả'),
                                      maxLines: 3),
                                ])))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate() ||
                            selectedCategory.isEmpty) return;
                        final category = provider.categories
                            .firstWhere((e) => e.id == selectedCategory);
                        try {
                          await provider.saveProduct(Product(
                              id: old?.id ?? '',
                              title: title.text.trim(),
                              price: int.parse(price.text),
                              salePrice: int.tryParse(salePrice.text),
                              thumbnail: image.text.trim(),
                              images: image.text.trim().isEmpty
                                  ? []
                                  : [image.text.trim()],
                              description: description.text.trim(),
                              categoryId: category.id,
                              categoryName: category.name,
                              metaInfo: old?.metaInfo ?? const {},
                              stock: int.tryParse(stock.text) ?? 0,
                              rating: old?.rating ?? 0,
                              sold: old?.sold ?? 0));
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                          if (context.mounted)
                            _message(context, 'Đã lưu sản phẩm');
                        } catch (e) {
                          if (context.mounted)
                            _message(context, '$e', error: true);
                        }
                      },
                      child: const Text('Lưu'))
                ],
              )));
}

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});
  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  String status = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();

      if (auth.isAdmin) {
        context.read<AdminProvider>().loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    final items = provider.orders
        .where(
          (order) => status.isEmpty || order.status == status,
        )
        .toList();

    return _AdminScaffold(
      title: 'Quản lý đơn hàng',
      onRefresh: provider.loadOrders,
      extraFilter: DropdownButtonFormField<String>(
        value: status,
        decoration: const InputDecoration(
          labelText: 'Trạng thái',
        ),
        items: const [
          DropdownMenuItem(
            value: '',
            child: Text('Tất cả'),
          ),
          DropdownMenuItem(
            value: 'pending',
            child: Text('Chờ xác nhận'),
          ),
          DropdownMenuItem(
            value: 'confirmed',
            child: Text('Đã xác nhận'),
          ),
          DropdownMenuItem(
            value: 'shipping',
            child: Text('Đang giao'),
          ),
          DropdownMenuItem(
            value: 'delivered',
            child: Text('Đã giao'),
          ),
          DropdownMenuItem(
            value: 'cancelled',
            child: Text('Đã hủy'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            status = value ?? '';
          });
        },
      ),
      child: _loadingOrEmpty(
        provider,
        items,
        'Chưa có đơn hàng',
        () => Column(
          children: items.map((order) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(
                        order: order,
                        adminMode: true,
                      ),
                    ),
                  );

                  if (!context.mounted) return;

                  await context.read<AdminProvider>().loadOrders();
                },
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.receipt_long_outlined,
                  ),
                ),
                title: Text(
                  'Đơn #${_shortOrderId(order.id)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}'
                    '\n${order.items.length} sản phẩm'
                    '\n${_money.format(order.totalAmount)}',
                  ),
                ),
                isThreeLine: true,
                trailing: SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _validOrderStatus(order.status),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Chờ xác nhận'),
                      ),
                      DropdownMenuItem(
                        value: 'confirmed',
                        child: Text('Đã xác nhận'),
                      ),
                      DropdownMenuItem(
                        value: 'shipping',
                        child: Text('Đang giao'),
                      ),
                      DropdownMenuItem(
                        value: 'delivered',
                        child: Text('Đã giao'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Đã hủy'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null || value == order.status) {
                        return;
                      }

                      try {
                        await context
                            .read<AdminProvider>()
                            .updateOrderStatus(order.id, value);

                        if (!context.mounted) return;

                        _message(
                          context,
                          'Đã cập nhật đơn hàng',
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        _message(
                          context,
                          'Không thể cập nhật đơn hàng: $e',
                          error: true,
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

String _shortOrderId(String id) {
  if (id.isEmpty) return 'Không xác định';
  return id.length > 8 ? id.substring(0, 8) : id;
}

String _validOrderStatus(String value) {
  const validStatuses = {
    'pending',
    'confirmed',
    'shipping',
    'delivered',
    'cancelled',
  };

  return validStatuses.contains(value) ? value : 'pending';
}

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();

      if (auth.isAdmin) {
        context.read<AdminProvider>().loadUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    final items = provider.users.where((user) {
      final searchValue =
          '${user.fullName} ${user.email} ${user.phone}'.toLowerCase();

      return searchValue.contains(query.toLowerCase());
    }).toList();

    return _AdminScaffold(
      title: 'Quản lý người dùng',
      onRefresh: provider.loadUsers,
      searchHint: 'Tìm tên, email hoặc số điện thoại',
      onSearch: (value) {
        setState(() {
          query = value;
        });
      },
      child: _loadingOrEmpty(
        provider,
        items,
        'Chưa có người dùng',
        () => Column(
          children: items.map((user) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundImage:
                      user.avatar.isEmpty ? null : NetworkImage(user.avatar),
                  child: user.avatar.isEmpty
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                title: Text(
                  user.fullName.isEmpty ? 'Chưa cập nhật tên' : user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${user.email}\n'
                  '${user.phone.isEmpty ? 'Chưa có số điện thoại' : user.phone}',
                ),
                isThreeLine: true,
                trailing: OutlinedButton.icon(
                  onPressed: () {
                    _showUserDialog(context, user);
                  },
                  icon: const Icon(
                    Icons.manage_accounts_outlined,
                  ),
                  label: const Text('Quản lý'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

Future<void> _showUserDialog(BuildContext context, AppUser user) async {
  final p = context.read<AdminProvider>();
  final fields = await p.getUserAdminFields(user.id);
  if (!context.mounted) return;
  String role = fields['role'];
  bool active = fields['isActive'];
  await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (_, setState) => AlertDialog(
                  title:
                      Text(user.fullName.isEmpty ? user.email : user.fullName),
                  content: SizedBox(
                      width: 420,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        DropdownButtonFormField<String>(
                            value: role,
                            decoration:
                                const InputDecoration(labelText: 'Vai trò'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'user', child: Text('User')),
                              DropdownMenuItem(
                                  value: 'admin', child: Text('Admin'))
                            ],
                            onChanged: (v) =>
                                setState(() => role = v ?? 'user')),
                        const SizedBox(height: 12),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tài khoản hoạt động'),
                            value: active,
                            onChanged: (v) => setState(() => active = v))
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () async {
                          await p.updateUserAdminFields(user.id,
                              role: role, isActive: active);
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                          if (context.mounted)
                            _message(context, 'Đã cập nhật người dùng');
                        },
                        child: const Text('Lưu'))
                  ])));
}

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});
  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  String query = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AdminProvider>().loadVouchers());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminProvider>();
    final items = p.vouchers
        .where((e) => '${e.code} ${e.description}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    return _AdminScaffold(
        title: 'Quản lý voucher',
        actionLabel: 'Thêm voucher',
        onAdd: () => _showVoucherDialog(context),
        onRefresh: p.loadVouchers,
        searchHint: 'Tìm mã hoặc mô tả voucher',
        onSearch: (v) => setState(() => query = v),
        child: _loadingOrEmpty(
            p,
            items,
            'Chưa có voucher',
            () => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return _AdminCard(
                      icon: Icons.local_offer_outlined,
                      title: item.code,
                      subtitle:
                          '${item.description}\nĐơn tối thiểu ${_money.format(item.minimumOrder)}',
                      badge:
                          'Giảm ${item.discountPercent}% • ${item.isActive ? 'Đang bật' : 'Đã tắt'}',
                      onEdit: () => _showVoucherDialog(context, item),
                      onDelete: () => _confirm(
                          context,
                          'Xóa voucher ${item.code}?',
                          () => context
                              .read<AdminProvider>()
                              .deleteVoucher(item.id)));
                })));
  }
}

Future<void> _showVoucherDialog(BuildContext context, [Voucher? old]) async {
  final formKey = GlobalKey<FormState>();
  final code = TextEditingController(text: old?.code ?? '');
  final description = TextEditingController(text: old?.description ?? '');
  final discount = TextEditingController(text: '${old?.discountPercent ?? 10}');
  final minimum = TextEditingController(text: '${old?.minimumOrder ?? 0}');
  DateTime start = old?.startDate ?? DateTime.now();
  DateTime end = old?.endDate ?? DateTime.now().add(const Duration(days: 30));
  bool active = old?.isActive ?? true;
  await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (_, setState) => AlertDialog(
                  title: Text(old == null ? 'Thêm voucher' : 'Sửa voucher'),
                  content: SizedBox(
                      width: 540,
                      child: SingleChildScrollView(
                          child: Form(
                              key: formKey,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                        controller: code,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        decoration: const InputDecoration(
                                            labelText: 'Mã voucher *'),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Vui lòng nhập mã'
                                                : null),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                        controller: description,
                                        decoration: const InputDecoration(
                                            labelText: 'Mô tả')),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      Expanded(
                                          child: TextFormField(
                                              controller: discount,
                                              decoration: const InputDecoration(
                                                  labelText: 'Giảm (%)'),
                                              keyboardType:
                                                  TextInputType.number)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: TextFormField(
                                              controller: minimum,
                                              decoration: const InputDecoration(
                                                  labelText: 'Đơn tối thiểu'),
                                              keyboardType:
                                                  TextInputType.number))
                                    ]),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      Expanded(
                                          child: OutlinedButton(
                                              onPressed: () async {
                                                final d = await showDatePicker(
                                                    context: dialogContext,
                                                    initialDate: start,
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime(2100));
                                                if (d != null)
                                                  setState(() => start = d);
                                              },
                                              child: Text(
                                                  'Từ ${DateFormat('dd/MM/yyyy').format(start)}'))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: OutlinedButton(
                                              onPressed: () async {
                                                final d = await showDatePicker(
                                                    context: dialogContext,
                                                    initialDate: end,
                                                    firstDate: start,
                                                    lastDate: DateTime(2100));
                                                if (d != null)
                                                  setState(() => end = d);
                                              },
                                              child: Text(
                                                  'Đến ${DateFormat('dd/MM/yyyy').format(end)}')))
                                    ]),
                                    SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Kích hoạt voucher'),
                                        value: active,
                                        onChanged: (v) =>
                                            setState(() => active = v))
                                  ])))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final percent = int.tryParse(discount.text) ?? 0;
                          if (percent < 1 || percent > 100) {
                            _message(
                                context, 'Phần trăm giảm phải từ 1 đến 100',
                                error: true);
                            return;
                          }
                          await context.read<AdminProvider>().saveVoucher(
                              Voucher(
                                  id: old?.id ?? '',
                                  code: code.text,
                                  description: description.text,
                                  discountPercent: percent,
                                  minimumOrder: int.tryParse(minimum.text) ?? 0,
                                  startDate: start,
                                  endDate: end,
                                  isActive: active));
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                          if (context.mounted)
                            _message(context, 'Đã lưu voucher');
                        },
                        child: const Text('Lưu'))
                  ])));
}

Widget _loadingOrEmpty(AdminProvider provider, List<dynamic> items,
    String emptyText, Widget Function() content) {
  if (provider.isLoading && items.isEmpty)
    return const Padding(
        padding: EdgeInsets.all(80),
        child: Center(child: CircularProgressIndicator()));
  if (provider.errorMessage != null && items.isEmpty)
    return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
            child: Text(provider.errorMessage!, textAlign: TextAlign.center)));
  if (items.isEmpty)
    return Padding(
        padding: const EdgeInsets.all(70),
        child: Center(
            child: Column(children: [
          const Icon(Icons.inbox_outlined, size: 56, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(emptyText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))
        ])));
  return content();
}

class _AdminScaffold extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAdd;
  final Future<void> Function() onRefresh;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final Widget? extraFilter;
  final Widget child;
  const _AdminScaffold(
      {required this.title,
      this.actionLabel,
      this.onAdd,
      required this.onRefresh,
      this.searchHint,
      this.onSearch,
      this.extraFilter,
      required this.child});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không có quyền truy cập')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Bạn không có quyền truy cập chức năng quản trị.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: onAdd == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(actionLabel ?? 'Thêm')),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFFE3ED),
                                    Color(0xFFFFF4F8)
                                  ]),
                                  borderRadius: BorderRadius.circular(22)),
                              child: Text(title,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.pastelPinkDark))),
                          if (searchHint != null || extraFilter != null) ...[
                            const SizedBox(height: 18),
                            LayoutBuilder(builder: (_, c) {
                              final search = searchHint == null
                                  ? null
                                  : TextField(
                                      decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.search),
                                          hintText: searchHint),
                                      onChanged: onSearch);
                              if (c.maxWidth < 700)
                                return Column(children: [
                                  if (search != null) search,
                                  if (search != null && extraFilter != null)
                                    const SizedBox(height: 12),
                                  if (extraFilter != null) extraFilter!
                                ]);
                              return Row(children: [
                                if (search != null)
                                  Expanded(flex: 2, child: search),
                                if (search != null && extraFilter != null)
                                  const SizedBox(width: 12),
                                if (extraFilter != null)
                                  Expanded(child: extraFilter!)
                              ]);
                            })
                          ],
                          const SizedBox(height: 18),
                          child,
                        ]))),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AdminCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.badge,
      this.imageUrl = '',
      required this.onEdit,
      required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 50,
                    height: 50,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(14)),
                    child: imageUrl.isEmpty
                        ? Icon(icon, color: AppColors.pastelPinkDark)
                        : Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(icon, color: AppColors.pastelPinkDark))),
                const Spacer(),
                PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Chỉnh sửa')),
                          PopupMenuItem(value: 'delete', child: Text('Xóa'))
                        ])
              ]),
              const SizedBox(height: 14),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Expanded(
                  child: Text(subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.muted, height: 1.4))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(badge,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.pastelGreenDark))),
            ])));
  }
}

Future<void> _confirm(
    BuildContext context, String title, Future<void> Function() action) async {
  final yes = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: Text(title),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'))
                  ])) ??
      false;
  if (!yes || !context.mounted) return;
  try {
    await action();
    if (context.mounted) _message(context, 'Đã xóa thành công');
  } catch (e) {
    if (context.mounted) _message(context, '$e', error: true);
  }
}

void _message(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.red.shade700 : null));
}
