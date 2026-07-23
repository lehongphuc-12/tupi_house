import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_image.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Bộ sưu tập'),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryPink,
        onRefresh: provider.fetchCategories,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePadding = constraints.maxWidth < 600 ? 20.0 : 28.0;
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          20,
                          sidePadding,
                          28,
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chạm vào những điều làm tổ ấm đẹp hơn',
                              style: TextStyle(
                                fontSize: 27,
                                height: 1.2,
                                letterSpacing: -0.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Khám phá các bộ sưu tập decor và sản phẩm handmade được tuyển chọn cho từng góc nhỏ trong nhà.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (provider.isLoading && categories.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  )
                else if (provider.errorMessage != null && categories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _CategoriesMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Chưa thể tải bộ sưu tập',
                      description: 'Không thể tải bộ sưu tập. Vui lòng kiểm tra kết nối và thử lại.',
                      actionLabel: 'Thử lại',
                      onPressed: provider.fetchCategories,
                    ),
                  )
                else if (categories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _CategoriesMessage(
                      icon: Icons.local_florist_outlined,
                      title: 'Danh mục đang được cập nhật',
                      description:
                          'Các bộ sưu tập mới sẽ sớm xuất hiện tại đây.',
                      actionLabel: 'Làm mới',
                      onPressed: provider.fetchCategories,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      0,
                      sidePadding,
                      36,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, sliverConstraints) {
                        final width = sliverConstraints.crossAxisExtent;
                        final maxExtent = width < 600 ? width : 520.0;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: maxExtent,
                            mainAxisExtent: width < 600 ? 230 : 270,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final category = categories[index];
                              return _CollectionCard(
                                category: category,
                                onTap: () {
                                  context
                                      .read<ProductProvider>()
                                      .setCategoryFilter(category.id);
                                  Navigator.maybePop(context);
                                },
                              );
                            },
                            childCount: categories.length,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CollectionCard extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.category,
    required this.onTap,
  });

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.07 : 0.045),
              blurRadius: _hovered ? 22 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: AppColors.lightCream,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(
                  path: widget.category.image,
                  fit: BoxFit.cover,
                  iconSize: 54,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x16000000),
                        Color(0xB3000000),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 0.62, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.category.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.category.description.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primaryPink,
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
  }
}

class _CategoriesMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onPressed;

  const _CategoriesMessage({
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: AppColors.softPink,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: AppColors.primaryPink),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
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
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => onPressed(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
