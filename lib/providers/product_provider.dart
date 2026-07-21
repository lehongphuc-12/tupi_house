import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

enum SortOption { none, priceAsc, priceDesc, ratingHigh, bestSelling }

class FilterState {
  final String? categoryId;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final bool onlyInStock;
  final SortOption sortOption;

  const FilterState({
    this.categoryId,
    this.minPrice = 0,
    this.maxPrice = 2000000,
    this.minRating = 0.0,
    this.onlyInStock = false,
    this.sortOption = SortOption.none,
  });

  FilterState copyWith({
    String? categoryId,
    bool resetCategory = false,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? onlyInStock,
    SortOption? sortOption,
  }) {
    return FilterState(
      categoryId: resetCategory ? null : (categoryId ?? this.categoryId),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _allProducts = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  
  // Trạng thái bộ lọc
  FilterState _filterState = const FilterState();
  FilterState get filterState => _filterState;

  // Phân trang (Lazy Loading)
  int _displayedCount = 4;
  int get displayedCount => _displayedCount;

  // Backwards compatibility for sortOption
  SortOption get sortOption => _filterState.sortOption;

  // Toàn bộ pipeline lọc
  List<Product> get filteredProducts {
    List<Product> list = _allProducts.where((p) {
      // 1. Lọc từ khóa tìm kiếm (theo tên hoặc danh mục)
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final titleMatch = p.title.toLowerCase().contains(query);
        final catMatch = p.categoryName.toLowerCase().contains(query);
        if (!titleMatch && !catMatch) return false;
      }

      // 2. Lọc theo danh mục
      if (_filterState.categoryId != null && _filterState.categoryId!.isNotEmpty) {
        if (p.categoryId != _filterState.categoryId) return false;
      }

      // 3. Lọc theo khoảng giá
      final effectivePrice = (p.salePrice ?? p.price).toDouble();
      if (effectivePrice < _filterState.minPrice ||
          effectivePrice > _filterState.maxPrice) {
        return false;
      }

      // 4. Lọc theo điểm đánh giá tối thiểu (Rating)
      if (p.rating < _filterState.minRating) return false;

      // 5. Lọc chỉ sản phẩm còn hàng
      if (_filterState.onlyInStock && p.stock <= 0) return false;

      return true;
    }).toList();

    // 6. Sắp xếp
    switch (_filterState.sortOption) {
      case SortOption.priceAsc:
        list.sort((a, b) => (a.salePrice ?? a.price).compareTo(b.salePrice ?? b.price));
        break;
      case SortOption.priceDesc:
        list.sort((a, b) => (b.salePrice ?? b.price).compareTo(a.salePrice ?? a.price));
        break;
      case SortOption.ratingHigh:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.bestSelling:
        list.sort((a, b) => b.sold.compareTo(a.sold));
        break;
      case SortOption.none:
        break;
    }

    return list;
  }

  // Danh sách sản phẩm trả về cho các trang legacy
  List<Product> get products => filteredProducts;

  // Lát cắt sản phẩm hiển thị trên UI (Pagination)
  List<Product> get displayedProducts {
    final list = filteredProducts;
    if (_displayedCount >= list.length) return list;
    return list.take(_displayedCount).toList();
  }

  bool get hasMore => _displayedCount < filteredProducts.length;

  /// Tải thêm 4 sản phẩm khi cuộn đến gần cuối trang
  void loadMore() {
    if (hasMore) {
      _displayedCount += 4;
      notifyListeners();
    }
  }

  void resetPagination() {
    _displayedCount = 4;
  }

  // Lấy tất cả sản phẩm từ Firestore (real-time stream)
  Stream<List<Product>> get productsStream {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    });
  }

  Future<void> fetchProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('products').get();
      _allProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();

      _allProducts.sort((a, b) => a.title.compareTo(b.title));
      _displayedCount = 4; // Reset phân trang về 4 sản phẩm
    } catch (e) {
      errorMessage = 'Không tải được danh sách sản phẩm: $e';
      _allProducts = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    _displayedCount = 4; // Reset phân trang khi tìm kiếm
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _filterState = _filterState.copyWith(sortOption: option);
    _displayedCount = 4;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      _filterState = _filterState.copyWith(resetCategory: true);
    } else {
      _filterState = _filterState.copyWith(categoryId: categoryId);
    }
    _displayedCount = 4;
    notifyListeners();
  }

  void applyFilterState(FilterState newState) {
    _filterState = newState;
    _displayedCount = 4;
    notifyListeners();
  }

  void resetFilters() {
    _filterState = const FilterState();
    _displayedCount = 4;
    notifyListeners();
  }

  // Thêm sản phẩm mới
  Future<bool> addProduct(Product product) async {
    try {
      await _firestore.collection('products').add(product.toJson());
      await fetchProducts();
      return true;
    } catch (e) {
      errorMessage = 'Thêm sản phẩm thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  // Cập nhật sản phẩm
  Future<bool> updateProduct(Product product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toJson());
      await fetchProducts();
      return true;
    } catch (e) {
      errorMessage = 'Cập nhật sản phẩm thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  // Xóa sản phẩm
  Future<bool> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
      _allProducts.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Xóa sản phẩm thất bại: $e';
      notifyListeners();
      return false;
    }
  }
}
