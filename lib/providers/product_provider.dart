import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/category.dart';

enum SortOption {
  none,
  priceAsc,
  priceDesc,
  ratingDesc,
  soldDesc,
  newest,
}

class FilterState {
  final String? categoryId;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final bool inStockOnly;

  const FilterState({
    this.categoryId,
    this.minPrice = 0,
    this.maxPrice = 10000000,
    this.minRating = 0,
    this.inStockOnly = false,
  });

  bool get hasActiveFilters =>
      categoryId != null ||
      minPrice > 0 ||
      maxPrice < 10000000 ||
      minRating > 0 ||
      inStockOnly;

  int get activeCount {
    int count = 0;
    if (categoryId != null) count++;
    if (minPrice > 0 || maxPrice < 10000000) count++;
    if (minRating > 0) count++;
    if (inStockOnly) count++;
    return count;
  }

  FilterState copyWith({
    String? categoryId,
    bool clearCategory = false,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStockOnly,
  }) {
    return FilterState(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }

  static const FilterState empty = FilterState();
}

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Raw data ───────────────────────────────────────────────
  List<Product> _allProducts = [];
  List<Category> _categories = [];

  // ── State ──────────────────────────────────────────────────
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  // ── Search / Filter / Sort ─────────────────────────────────
  String _searchQuery = '';
  SortOption _sortOption = SortOption.none;
  FilterState _filter = FilterState.empty;

  // ── Pagination ─────────────────────────────────────────────
  static const int _pageSize = 4;
  int _displayedCount = _pageSize;


  // ── Getters ────────────────────────────────────────────────
  List<Category> get categories => _categories;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  FilterState get filter => _filter;

  List<Product> get products {
    // 1. Search
    List<Product> list = _allProducts.where((p) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q);
    }).toList();

    // 2. Filter
    if (_filter.categoryId != null) {
      list = list.where((p) => p.categoryId == _filter.categoryId).toList();
    }
    if (_filter.minPrice > 0) {
      list = list.where((p) => p.price >= _filter.minPrice).toList();
    }
    if (_filter.maxPrice < 10000000) {
      list = list.where((p) => p.price <= _filter.maxPrice).toList();
    }
    if (_filter.minRating > 0) {
      list = list.where((p) => p.rating >= _filter.minRating).toList();
    }
    if (_filter.inStockOnly) {
      list = list.where((p) => p.stock > 0).toList();
    }

    // 3. Sort
    switch (_sortOption) {
      case SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.soldDesc:
        list.sort((a, b) => b.sold.compareTo(a.sold));
        break;
      case SortOption.newest:
        // Giữ thứ tự fetchProducts (đã sort newest khi load)
        break;
      case SortOption.none:
        break;
    }

    return list;
  }

  /// Slice hiển thị theo pagination
  List<Product> get displayedProducts {
    final all = products;
    if (_displayedCount >= all.length) {
      hasMore = false;
      return all;
    }
    hasMore = true;
    return all.take(_displayedCount).toList();
  }

  int get totalFilteredCount => products.length;

  // ── Fetch ──────────────────────────────────────────────────
  Future<void> fetchProducts() async {
    isLoading = true;
    errorMessage = null;
    _displayedCount = _pageSize;
    notifyListeners();

    try {
      final snap = await _firestore.collection('products').get();
      _allProducts = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();

      // Sort mặc định: newest → dùng createdAt nếu có, fallback theo tên
      _allProducts.sort((a, b) => a.title.compareTo(b.title));
    } catch (e) {
      errorMessage = 'Không tải được danh sách sản phẩm: $e';
      _allProducts = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final snap = await _firestore
          .collection('categories')
          .orderBy('order')
          .get();
      _categories = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Category.fromJson(data);
      }).toList();
      notifyListeners();
    } catch (_) {
      // Không có index → fallback
      final snap = await _firestore.collection('categories').get();
      _categories = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Category.fromJson(data);
      }).toList();
      notifyListeners();
    }
  }

  void loadMore() {
    if (isLoadingMore || !hasMore) return;
    _displayedCount += _pageSize;
    notifyListeners();
  }

  // ── Search / Filter / Sort setters ────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    _displayedCount = _pageSize;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _displayedCount = _pageSize;
    notifyListeners();
  }

  void applyFilter(FilterState newFilter) {
    _filter = newFilter;
    _displayedCount = _pageSize;
    notifyListeners();
  }

  void resetFilters() {
    _filter = FilterState.empty;
    _sortOption = SortOption.none;
    _searchQuery = '';
    _displayedCount = _pageSize;
    notifyListeners();
  }

  // ── Legacy CRUD (giữ nguyên để không break code cũ) ───────
  Stream<List<Product>> get productsStream {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    });
  }

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
