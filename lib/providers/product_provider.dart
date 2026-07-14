import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

enum SortOption { none, priceAsc, priceDesc }

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _allProducts = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  SortOption sortOption = SortOption.none;

  List<Product> get products {
    List<Product> list = _allProducts.where((p) {
      if (searchQuery.trim().isEmpty) return true;
      return p.title.toLowerCase().contains(searchQuery.trim().toLowerCase()) ||
          p.categoryName.toLowerCase().contains(
                searchQuery.trim().toLowerCase(),
              );
    }).toList();

    switch (sortOption) {
      case SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.none:
        break;
    }
    return list;
  }

  // Lấy tất cả sản phẩm từ Firestore (real-time)
  Stream<List<Product>> get productsStream {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Quan trọng: gán id từ document ID
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

      // Sắp xếp mặc định theo tên
      _allProducts.sort((a, b) => a.title.compareTo(b.title));
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
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    sortOption = option;
    notifyListeners();
  }

  // Thêm sản phẩm mới
  Future<bool> addProduct(Product product) async {
    try {
      await _firestore.collection('products').add(product.toJson());
      await fetchProducts(); // Refresh lại danh sách
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
