import 'package:flutter/material.dart';

import '../../../models/category.dart';
import '../../../theme/app_theme.dart';
import '../../product_image.dart';

class AdminCategoryCard extends StatelessWidget {
  final Category category;
  final int? productCount;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminCategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    this.productCount,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(
                  path: category.image,
                  fit: BoxFit.cover,
                  iconSize: 48,
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0x52000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Thứ tự ${category.order}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.woodBrownDark,
                      ),
                    ),
                  ),
                ),
                if (isBusy)
                  const ColoredBox(
                    color: Color(0x4DFFFFFF),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category.description.trim().isEmpty
                            ? 'Chưa có mô tả'
                            : category.description.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (productCount != null) ...[
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: AppColors.sageGreenDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$productCount sản phẩm',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageGreenDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Chỉnh sửa danh mục',
                      onPressed: isBusy ? null : onEdit,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.softPink,
                        foregroundColor: AppColors.primaryPink,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    const SizedBox(height: 6),
                    IconButton.filledTonal(
                      tooltip: 'Xóa danh mục',
                      onPressed: isBusy ? null : onDelete,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.errorLight,
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
