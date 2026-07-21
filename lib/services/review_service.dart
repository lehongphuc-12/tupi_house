import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy danh sách đánh giá của sản phẩm (mới nhất xếp trước)
  Future<List<Review>> getReviewsForProduct(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      // Fallback không orderBy nếu chưa có index
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      final reviews = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Review.fromJson(data);
      }).toList();

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    }
  }

  /// Kiểm tra tài khoản người dùng đã đánh giá sản phẩm này chưa (chống spam)
  Future<bool> hasUserReviewed(String userId, String productId) async {
    if (userId.isEmpty || productId.isEmpty) return false;
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Thêm nhận xét mới và tự động tính toán lại điểm rating của sản phẩm
  Future<bool> addReview(Review review) async {
    try {
      // 1. Tạo bản ghi review mới trong collection `reviews`
      await _firestore.collection('reviews').add(review.toJson());

      // 2. Tính toán lại rating trung bình và reviewCount của sản phẩm
      final allReviews = await getReviewsForProduct(review.productId);
      if (allReviews.isNotEmpty) {
        final totalStars = allReviews.fold<double>(
          0.0,
          (acc, item) => acc + item.rating,
        );
        final avgRating =
            double.parse((totalStars / allReviews.length).toStringAsFixed(1));

        // 3. Cập nhật thẳng vào document sản phẩm
        await _firestore.collection('products').doc(review.productId).update({
          'rating': avgRating,
          'reviewCount': allReviews.length,
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
