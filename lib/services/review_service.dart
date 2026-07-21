import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;

  /// Lấy tất cả review của một sản phẩm
  Future<List<Review>> getReviews(String productId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _fromDoc(data);
      }).toList();
    } catch (_) {
      // Firestore index chưa tạo → fallback không orderBy
      final snap = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();
      final list = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _fromDoc(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
  }

  /// Kiểm tra user đã review sản phẩm này chưa
  Future<bool> hasUserReviewed(String productId, String userId) async {
    final snap = await _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Thêm review mới + cập nhật rating trung bình trong product doc
  Future<void> addReview(Review review) async {
    final batch = _db.batch();

    // 1. Thêm review doc
    final reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, {
      'productId': review.productId,
      'userId': review.userId,
      'userName': review.userName,
      'rating': review.rating,
      'comment': review.comment,
      'images': review.images,
      'createdAt': review.createdAt.toIso8601String(),
    });

    await batch.commit();

    // 2. Cập nhật rating trung bình trong product
    await _updateProductRating(review.productId);
  }

  /// Tính lại và cập nhật rating trung bình của product
  Future<void> _updateProductRating(String productId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (snap.docs.isEmpty) return;

      final total = snap.docs
          .map((d) => (d.data()['rating'] as num).toDouble())
          .reduce((a, b) => a + b);
      final avg = total / snap.docs.length;

      await _db.collection('products').doc(productId).update({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': snap.docs.length,
      });
    } catch (_) {}
  }

  Review _fromDoc(Map<String, dynamic> data) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return Review(
      id: data['id'] ?? '',
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Ẩn danh',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: parseDate(data['createdAt']),
    );
  }
}
