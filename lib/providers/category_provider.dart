import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Category> _categories = [];
  bool isLoading = false;
  String? errorMessage;

  List<Category> get categories => List.unmodifiable(_categories);

  Stream<List<Category>> get categoriesStream {
    return _firestore
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        return Category.fromJson(data);
      }).toList();
    });
  }

  Future<void> fetchCategories() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final snapshot =
          await _firestore.collection('categories').orderBy('order').get();

      _categories = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        return Category.fromJson(data);
      }).toList();
    } catch (e) {
      errorMessage = 'Không tải được danh mục: $e';
      _categories = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Category category) async {
    errorMessage = null;

    try {
      final document = _firestore.collection('categories').doc();

      final newCategory = Category(
        id: document.id,
        name: category.name.trim(),
        image: category.image.trim(),
        description: category.description.trim(),
        order: category.order,
      );

      await document.set(newCategory.toJson());
      await fetchCategories();

      return true;
    } catch (e) {
      errorMessage = 'Thêm danh mục thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    errorMessage = null;

    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toJson());

      await fetchCategories();

      return true;
    } catch (e) {
      errorMessage = 'Cập nhật danh mục thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    errorMessage = null;

    try {
      await _firestore.collection('categories').doc(categoryId).delete();

      _categories.removeWhere((category) => category.id == categoryId);
      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = 'Xóa danh mục thất bại: $e';
      notifyListeners();
      return false;
    }
  }

  bool categoryNameExists(
    String name, {
    String? excludedCategoryId,
  }) {
    final normalizedName = name.trim().toLowerCase();

    return _categories.any((category) {
      final isSameName = category.name.trim().toLowerCase() == normalizedName;
      final isExcluded = category.id == excludedCategoryId;

      return isSameName && !isExcluded;
    });
  }
}
