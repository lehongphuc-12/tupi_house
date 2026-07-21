import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Order>>? _subscription;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered getters
  List<Order> get allOrders => _orders;
  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == 'pending').toList();
  List<Order> get activeOrders => _orders
      .where((o) => o.status == 'confirmed' || o.status == 'shipping')
      .toList();
  List<Order> get deliveredOrders =>
      _orders.where((o) => o.status == 'delivered').toList();
  List<Order> get cancelledOrders =>
      _orders.where((o) => o.status == 'cancelled').toList();

  /// Lắng nghe real-time đơn hàng của user
  void listenToOrders(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.listenOrders(userId).listen(
      (orders) {
        _orders = orders;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Không thể tải đơn hàng. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Hủy đơn hàng (chỉ khi status = pending)
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _service.cancelOrder(orderId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể hủy đơn: $e';
      notifyListeners();
      return false;
    }
  }

  /// Tạo đơn hàng mới
  Future<bool> createOrder(Order order) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _service.createOrder(order);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể tạo đơn hàng: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Dừng lắng nghe khi user đăng xuất
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _orders = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
