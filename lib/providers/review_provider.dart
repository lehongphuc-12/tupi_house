import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _userHasReviewed = false;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get userHasReviewed => _userHasReviewed;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.map((r) => r.rating).reduce((a, b) => a + b);
    return total / _reviews.length;
  }

  /// Phân bổ số lượng theo từng mức sao (5→1)
  Map<int, int> get ratingDistribution {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final star = r.rating.round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
  }

  Future<void> fetchReviews(String productId, {String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _service.getReviews(productId);
      if (userId != null) {
        _userHasReviewed =
            await _service.hasUserReviewed(productId, userId);
      }
    } catch (e) {
      _errorMessage = 'Không thể tải đánh giá: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final review = Review(
        id: '',
        productId: productId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );
      await _service.addReview(review);
      _userHasReviewed = true;
      await fetchReviews(productId, userId: userId);
      return true;
    } catch (e) {
      _errorMessage = 'Gửi đánh giá thất bại: $e';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clear() {
    _reviews = [];
    _userHasReviewed = false;
    _errorMessage = null;
    notifyListeners();
  }
}
