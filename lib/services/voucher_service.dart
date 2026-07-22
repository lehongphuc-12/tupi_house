import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher.dart';

class VoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy thông tin voucher theo mã code (không phân biệt hoa thường)
  Future<Voucher?> getVoucher(String code) async {
    try {
      final query = code.trim().toUpperCase();
      final snapshot = await _firestore
          .collection('vouchers')
          .where('code', isEqualTo: query)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return Voucher.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra tính hợp lệ của voucher
  String? validateVoucher(Voucher voucher, int subtotalAmount) {
    if (!voucher.isActive) {
      return 'Mã giảm giá đã bị vô hiệu hóa';
    }

    final now = DateTime.now();
    if (now.isBefore(voucher.startDate)) {
      return 'Chưa đến thời gian áp dụng mã giảm giá';
    }
    if (now.isAfter(voucher.endDate)) {
      return 'Mã giảm giá đã hết hạn sử dụng';
    }

    if (voucher.usedCount >= voucher.usageLimit) {
      return 'Mã giảm giá đã hết lượt sử dụng';
    }

    if (subtotalAmount < voucher.minOrderValue) {
      return 'Đơn hàng chưa đạt giá trị tối thiểu (${voucher.minOrderValue}đ)';
    }

    return null; // Hợp lệ
  }

  /// Tính toán số tiền giảm giá
  int calculateDiscount(Voucher voucher, int subtotalAmount) {
    int discount = 0;
    if (voucher.type == 'percent') {
      discount = (subtotalAmount * (voucher.discountValue / 100.0)).floor();
      if (voucher.maxDiscountAmount != null) {
        discount = min(discount, voucher.maxDiscountAmount!);
      }
    } else if (voucher.type == 'fixed') {
      discount = voucher.discountValue;
    }

    // Đảm bảo số tiền giảm giá không lớn hơn tổng tiền hàng
    return min(discount, subtotalAmount);
  }

  /// Cập nhật số lần sử dụng của voucher
  Future<void> useVoucher(String voucherId) async {
    try {
      final docRef = _firestore.collection('vouchers').doc(voucherId);
      await docRef.update({
        'usedCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi cập nhật lượt dùng voucher: $e');
    }
  }
}
