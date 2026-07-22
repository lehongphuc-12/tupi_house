import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../services/voucher_service.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherService _service = VoucherService();

  Voucher? _appliedVoucher;
  int _discountAmount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  Voucher? get appliedVoucher => _appliedVoucher;
  int get discountAmount => _discountAmount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Áp dụng mã giảm giá
  Future<bool> applyVoucher(String code, int subtotalAmount) async {
    if (code.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập mã giảm giá';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final voucher = await _service.getVoucher(code);
      if (voucher == null) {
        _errorMessage = 'Mã giảm giá không tồn tại';
        _appliedVoucher = null;
        _discountAmount = 0;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final error = _service.validateVoucher(voucher, subtotalAmount);
      if (error != null) {
        _errorMessage = error;
        _appliedVoucher = null;
        _discountAmount = 0;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _appliedVoucher = voucher;
      _discountAmount = _service.calculateDiscount(voucher, subtotalAmount);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi áp dụng voucher: $e';
      _appliedVoucher = null;
      _discountAmount = 0;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Gỡ mã giảm giá
  void removeVoucher() {
    _appliedVoucher = null;
    _discountAmount = 0;
    _errorMessage = null;
    notifyListeners();
  }

  /// Khấu trừ lượt sử dụng voucher (khi đặt hàng thành công)
  Future<void> useAppliedVoucher() async {
    if (_appliedVoucher != null) {
      await _service.useVoucher(_appliedVoucher!.id);
      removeVoucher();
    }
  }

  /// Cập nhật lại discount khi subtotal thay đổi
  void updateSubtotal(int subtotalAmount) {
    if (_appliedVoucher != null) {
      final error = _service.validateVoucher(_appliedVoucher!, subtotalAmount);
      if (error != null) {
        removeVoucher();
      } else {
        _discountAmount = _service.calculateDiscount(_appliedVoucher!, subtotalAmount);
        notifyListeners();
      }
    }
  }
}
