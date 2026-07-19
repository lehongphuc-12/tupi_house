import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/wishlist.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _service = WishlistService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<WishlistItem> _items = [];
  bool isLoading = false;
  String? errorMessage;
  StreamSubscription? _wishlistSub;
  StreamSubscription? _authSub;

  List<WishlistItem> get items => _items;
  int get totalItems => _items.length;

  WishlistProvider() {
    // Automatically listen to auth changes
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToWishlist(user.uid);
      } else {
        _stopListening();
      }
    });
  }

  bool isFavorite(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  void _listenToWishlist(String userId) {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _wishlistSub?.cancel();
    _wishlistSub = _service.getWishlistRawStream().listen(
      (rawItems) async {
        try {
          List<WishlistItem> mappedItems = [];
          for (var raw in rawItems) {
            final productId = raw['productId'] as String;
            final createdAtVal = raw['createdAt'];
            DateTime addedAt = DateTime.now();
            if (createdAtVal is Timestamp) {
              addedAt = createdAtVal.toDate();
            } else if (createdAtVal is String) {
              addedAt = DateTime.tryParse(createdAtVal) ?? DateTime.now();
            }

            // Fetch product details from the products collection in Firestore
            final productDoc = await _firestore.collection('products').doc(productId).get();
            if (productDoc.exists) {
              final data = productDoc.data()!;
              data['id'] = productDoc.id;
              final product = Product.fromJson(data);

              mappedItems.add(WishlistItem(
                productId: productId,
                title: product.title,
                price: product.price,
                thumbnail: product.thumbnail,
                categoryName: product.categoryName,
                addedAt: addedAt,
              ));
            }
          }
          mappedItems.sort((a, b) => b.addedAt.compareTo(a.addedAt));
          _items = mappedItems;
          isLoading = false;
          errorMessage = null;
          notifyListeners();
        } catch (e) {
          errorMessage = 'Lỗi tải danh sách yêu thích: $e';
          isLoading = false;
          notifyListeners();
        }
      },
      onError: (e) {
        errorMessage = 'Lỗi tải danh sách yêu thích: $e';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> toggleWishlist(Product product) async {
    try {
      await _service.toggleWishlist(product);
    } catch (e) {
      errorMessage = 'Không thể thay đổi yêu thích: $e';
      notifyListeners();
      rethrow;
    }
  }

  void _stopListening() {
    _wishlistSub?.cancel();
    _wishlistSub = null;
    _items = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _wishlistSub?.cancel();
    super.dispose();
  }
}
