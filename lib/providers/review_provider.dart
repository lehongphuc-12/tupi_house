import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Điểm đánh giá trung bình từ danh sách review hiện tại
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(0.0, (sum, r) => sum + r.rating);
    return double.parse((total / _reviews.length).toStringAsFixed(1));
  }

  /// Thống kê tỉ lệ sao (key: 1..5, value: số lượng)
  Map<int, int> get ratingDistribution {
    final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _reviews) {
      final star = review.rating.round().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return dist;
  }

  /// Tải danh sách đánh giá của sản phẩm
  Future<void> loadReviews(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _service.getReviewsForProduct(productId);
    } catch (e) {
      _errorMessage = 'Không thể tải nhận xét: $e';
      _reviews = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gửi nhận xét đánh giá mới
  Future<bool> submitReview(Review review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _service.addReview(review);
    if (success) {
      // Reload lại danh sách sau khi thêm mới thành công
      _reviews = await _service.getReviewsForProduct(review.productId);
    } else {
      _errorMessage = 'Không thể gửi nhận xét. Vui lòng thử lại.';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
