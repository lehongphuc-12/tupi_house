import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception("Vui lòng đăng nhập để sử dụng danh sách yêu thích");
    }
  }

  // Toggle wishlist item
  Future<void> toggleWishlist(Product product) async {
    try {
      final uid = _userId; // will throw if not logged in
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .doc(product.id);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'productId': product.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Check favorite status (one-off check if needed)
  Future<bool> isFavorite(String productId) async {
    try {
      final uid = _userId;
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .doc(productId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Real-time raw items stream containing productId and createdAt
  Stream<List<Map<String, dynamic>>> getWishlistRawStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'productId': doc.id,
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }
}
