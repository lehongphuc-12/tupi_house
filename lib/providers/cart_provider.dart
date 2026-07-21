import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  Cart _cart = Cart(userId: '');

  Cart get cart => _cart;

  CartProvider() {
    _initCart();
  }

  Future<void> _initCart() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _loadCart();
  }

  void _loadCart() {
    _cartService.getCartStream().listen((newCart) {
      _cart = newCart;
      notifyListeners();
    });
  }

  Future<void> addToCart(CartItem item) async {
    await _cartService.addToCart(item);
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    await _cartService.updateQuantity(productId, quantity);
  }

  Future<void> removeItem(String productId) async {
    await _cartService.removeItem(productId);
  }

  Future<void> clearCart() async {
    await _cartService.clearCart();
  }
}
