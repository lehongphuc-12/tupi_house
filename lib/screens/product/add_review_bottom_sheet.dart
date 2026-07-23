import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/star_rating_bar.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final Product product;

  const AddReviewBottomSheet({super.key, required this.product});

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkUserReviewStatus();
  }

  Future<void> _checkUserReviewStatus() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.currentUser != null) {
      final reviewed = await ReviewService()
          .hasUserReviewed(auth.currentUser!.id, widget.product.id);
      if (mounted && reviewed) {
        setState(() => _alreadyReviewed = true);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá.')),
      );
      return;
    }

    if (_alreadyReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã đánh giá sản phẩm này rồi!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final newReview = Review(
      id: '',
      productId: widget.product.id,
      userId: auth.currentUser!.id,
      userName: auth.currentUser!.fullName.isNotEmpty
          ? auth.currentUser!.fullName
          : 'Khách hàng',
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success =
        await context.read<ReviewProvider>().submitReview(newReview);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Cảm ơn bạn đã gửi đánh giá!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ Không thể gửi đánh giá. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineSoft,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const SizedBox(width: 44),
                const Expanded(
                  child: Text(
                    'Đánh giá sản phẩm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: 'Đóng',
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.product.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            if (_alreadyReviewed) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.pastelGreenDark),
                    SizedBox(width: 8),
                    Text(
                      'Bạn đã gửi nhận xét cho sản phẩm này.',
                      style: TextStyle(
                        color: AppColors.pastelGreenDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Interactive Star Rating Selector
              StarRatingBar(
                rating: _rating,
                starSize: 36,
                isInteractive: true,
                onRatingChanged: (val) => setState(() => _rating = val),
              ),
              const SizedBox(height: 8),
              Text(
                _ratingLabel(_rating),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pastelPinkDark,
                ),
              ),
              const SizedBox(height: 20),

              // Comment Input
              TextField(
                controller: _commentController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Nhận xét của bạn',
                  alignLabelWithHint: true,
                  hintText:
                      'Chia sẻ cảm nhận của bạn về sản phẩm này nhé (chất lượng, thiết kế, đóng gói...)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gửi đánh giá'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating >= 5) return 'Tuyệt vời 😍';
    if (rating >= 4) return 'Rất tốt 😊';
    if (rating >= 3) return 'Bình thường 🙂';
    if (rating >= 2) return 'Tạm được 😐';
    return 'Không hài lòng 🙁';
  }
}
