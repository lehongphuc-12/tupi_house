import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception("Vui lòng đăng nhập để sử dụng giỏ hàng");
    }
  }

  CollectionReference<Map<String, dynamic>> get _cartRef =>
      _firestore.collection('users').doc(_userId).collection('cart');

  Future<void> addToCart(CartItem item) async {
    try {
        final user = _auth.currentUser;

        if (user == null) {
            throw Exception("User chưa đăng nhập");
        }

        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(item.productId);
        final doc = await docRef.get();

      if (doc.exists) {
        final currentQty = (doc.data()?['quantity'] as int?) ?? 1;
        await docRef.update({
          'quantity': currentQty + item.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          ...item.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity < 1) return;
    await _cartRef.doc(productId).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeItem(String productId) async {
    await _cartRef.doc(productId).delete();
  }

  Stream<Cart> getCartStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(Cart(userId: '', items: []));
    }
    return _cartRef.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => CartItem.fromJson(doc.data()))
          .toList();
      return Cart(userId: user.uid, items: items);
    });
  }

  Future<void> clearCart() async {
    final batch = _firestore.batch();
    final snapshot = await _cartRef.get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}