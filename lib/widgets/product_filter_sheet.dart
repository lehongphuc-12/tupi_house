import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({super.key});

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late String? _selectedCatId;
  late RangeValues _priceRange;
  late double _minRating;
  late bool _onlyInStock;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    final state = provider.filterState;

    _selectedCatId = state.categoryId;
    _priceRange = RangeValues(state.minPrice, state.maxPrice);
    _minRating = state.minRating;
    _onlyInStock = state.onlyInStock;
    _sortOption = state.sortOption;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  String _formatVND(double value) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(value);
  }

  void _reset() {
    setState(() {
      _selectedCatId = null;
      _priceRange = const RangeValues(0, 2000000);
      _minRating = 0.0;
      _onlyInStock = false;
      _sortOption = SortOption.none;
    });
  }

  void _apply() {
    final newState = FilterState(
      categoryId: _selectedCatId,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      minRating: _minRating,
      onlyInStock: _onlyInStock,
      sortOption: _sortOption,
    );
    context.read<ProductProvider>().applyFilterState(newState);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle & title
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ lọc & Sắp xếp 🎛️',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Thiết lập lại'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // 1. Sắp xếp (Sort)
            const Text(
              'Sắp xếp theo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _sortChip('Mặc định', SortOption.none),
                _sortChip('Giá tăng dần ⬆️', SortOption.priceAsc),
                _sortChip('Giá giảm dần ⬇️', SortOption.priceDesc),
                _sortChip('Rating cao ⭐️', SortOption.ratingHigh),
                _sortChip('Bán chạy 🔥', SortOption.bestSelling),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Danh mục sản phẩm
            const Text(
              'Danh mục sản phẩm',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCatId == null || _selectedCatId!.isEmpty,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCatId = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) {
                    final isSelected = _selectedCatId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: AppColors.softPink,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.pastelPinkDark
                              : AppColors.ink,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCatId = selected ? cat.id : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Khoảng giá
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Khoảng giá',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_formatVND(_priceRange.start)} - ${_formatVND(_priceRange.end)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pastelPinkDark,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 2000000,
              divisions: 40,
              activeColor: AppColors.pastelPinkDark,
              inactiveColor: AppColors.softPink,
              labels: RangeLabels(
                _formatVND(_priceRange.start),
                _formatVND(_priceRange.end),
              ),
              onChanged: (values) {
                setState(() => _priceRange = values);
              },
            ),
            const SizedBox(height: 16),

            // 4. Đánh giá tối thiểu (Rating)
            const Text(
              'Đánh giá tối thiểu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ratingChip('Tất cả', 0.0),
                const SizedBox(width: 8),
                _ratingChip('3★+', 3.0),
                const SizedBox(width: 8),
                _ratingChip('4★+', 4.0),
                const SizedBox(width: 8),
                _ratingChip('5★', 5.0),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Trạng thái còn hàng
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Chỉ hiện sản phẩm còn hàng',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              activeThumbColor: AppColors.primaryPink,
              activeTrackColor: AppColors.primaryPinkLight,
              value: _onlyInStock,
              onChanged: (val) => setState(() => _onlyInStock = val),
            ),
            const SizedBox(height: 24),

            // Button Áp dụng
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Áp dụng bộ lọc'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label, SortOption option) {
    final isSelected = _sortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.softPink,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.pastelPinkDark : AppColors.ink,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _sortOption = option);
      },
    );
  }

  Widget _ratingChip(String label, double rating) {
    final isSelected = _minRating == rating;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.softPink,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.pastelPinkDark : AppColors.ink,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _minRating = rating);
      },
    );
  }
}
