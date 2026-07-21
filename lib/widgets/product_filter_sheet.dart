import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

/// Bottom sheet filter đa tiêu chí
class ProductFilterSheet extends StatefulWidget {
  final FilterState currentFilter;
  final List<Category> categories;
  final SortOption currentSort;
  final ValueChanged<FilterState> onApply;
  final ValueChanged<SortOption> onSortChanged;

  const ProductFilterSheet({
    super.key,
    required this.currentFilter,
    required this.categories,
    required this.currentSort,
    required this.onApply,
    required this.onSortChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required FilterState currentFilter,
    required List<Category> categories,
    required SortOption currentSort,
    required ValueChanged<FilterState> onApply,
    required ValueChanged<SortOption> onSortChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFilterSheet(
        currentFilter: currentFilter,
        categories: categories,
        currentSort: currentSort,
        onApply: onApply,
        onSortChanged: onSortChanged,
      ),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late FilterState _filter;
  late SortOption _sort;
  late RangeValues _priceRange;

  static const double _maxPrice = 2000000;

  String _formatPrice(double v) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
          .format(v);

  static const _sortLabels = {
    SortOption.none: 'Mặc định',
    SortOption.priceAsc: 'Giá tăng dần',
    SortOption.priceDesc: 'Giá giảm dần',
    SortOption.ratingDesc: 'Đánh giá cao nhất',
    SortOption.soldDesc: 'Bán chạy nhất',
    SortOption.newest: 'Mới nhất',
  };

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _sort = widget.currentSort;
    _priceRange = RangeValues(
      widget.currentFilter.minPrice.clamp(0, _maxPrice),
      widget.currentFilter.maxPrice.clamp(0, _maxPrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Text('Lọc & Sắp xếp',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter = FilterState.empty;
                        _sort = SortOption.none;
                        _priceRange =
                            const RangeValues(0, _maxPrice);
                      });
                    },
                    child: const Text('Xóa tất cả',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Sắp xếp ──────────────────────────────
                  _SectionTitle(title: 'Sắp xếp theo'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortOption.values.map((opt) {
                      final selected = _sort == opt;
                      return ChoiceChip(
                        label: Text(_sortLabels[opt] ?? ''),
                        selected: selected,
                        selectedColor: AppColors.softPink,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.pastelPinkDark
                              : AppColors.ink,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.pastelPinkDark
                              : const Color(0xFFE0D8DB),
                        ),
                        onSelected: (_) =>
                            setState(() => _sort = opt),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Danh mục ─────────────────────────────
                  _SectionTitle(title: 'Danh mục'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _filter.categoryId == null,
                        selectedColor: AppColors.softPink,
                        labelStyle: TextStyle(
                          color: _filter.categoryId == null
                              ? AppColors.pastelPinkDark
                              : AppColors.ink,
                          fontWeight: _filter.categoryId == null
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: _filter.categoryId == null
                              ? AppColors.pastelPinkDark
                              : const Color(0xFFE0D8DB),
                        ),
                        onSelected: (_) => setState(() =>
                            _filter = _filter.copyWith(
                                clearCategory: true)),
                      ),
                      ...widget.categories.map((cat) {
                        final selected = _filter.categoryId == cat.id;
                        return ChoiceChip(
                          label: Text(cat.name),
                          selected: selected,
                          selectedColor: AppColors.softPink,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.pastelPinkDark
                                : AppColors.ink,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppColors.pastelPinkDark
                                : const Color(0xFFE0D8DB),
                          ),
                          onSelected: (_) => setState(() =>
                              _filter = _filter.copyWith(
                                  categoryId: cat.id)),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Khoảng giá ───────────────────────────
                  _SectionTitle(title: 'Khoảng giá'),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatPrice(_priceRange.start),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600)),
                      Text(_priceRange.end >= _maxPrice
                          ? '${_formatPrice(_maxPrice)}+'
                          : _formatPrice(_priceRange.end),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.pastelPinkDark,
                      thumbColor: AppColors.pastelPinkDark,
                      overlayColor:
                          AppColors.pastelPinkDark.withValues(alpha: 0.15),
                      inactiveTrackColor: const Color(0xFFEEE0E5),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: _maxPrice,
                      divisions: 40,
                      onChanged: (v) {
                        setState(() {
                          _priceRange = v;
                          _filter = _filter.copyWith(
                            minPrice: v.start,
                            maxPrice: v.end,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Đánh giá tối thiểu ───────────────────
                  _SectionTitle(title: 'Đánh giá tối thiểu'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [0, 3, 4, 5].map((stars) {
                      final selected =
                          _filter.minRating == stars.toDouble();
                      return ChoiceChip(
                        label: stars == 0
                            ? const Text('Tất cả')
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$stars'),
                                  const SizedBox(width: 3),
                                  Icon(Icons.star_rounded,
                                      size: 14,
                                      color: selected
                                          ? AppColors.pastelPinkDark
                                          : Colors.amber),
                                ],
                              ),
                        selected: selected,
                        selectedColor: AppColors.softPink,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.pastelPinkDark
                              : AppColors.ink,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.pastelPinkDark
                              : const Color(0xFFE0D8DB),
                        ),
                        onSelected: (_) => setState(() =>
                            _filter = _filter.copyWith(
                                minRating: stars.toDouble())),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Chỉ còn hàng ─────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            color: AppColors.pastelGreenDark, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Chỉ hiển thị sản phẩm còn hàng',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pastelGreenDark)),
                        ),
                        Switch(
                          value: _filter.inStockOnly,
                          activeColor: AppColors.pastelGreenDark,
                          onChanged: (v) => setState(() =>
                              _filter = _filter.copyWith(inStockOnly: v)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.pastelPinkDark,
                        side: const BorderSide(
                            color: AppColors.pastelPinkDark),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        widget.onApply(_filter);
                        widget.onSortChanged(_sort);
                        Navigator.pop(context);
                      },
                      child: const Text('Áp dụng',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink));
  }
}
