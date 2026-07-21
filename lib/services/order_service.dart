import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Chuyển đổi Firestore doc → Order (xử lý cả Timestamp lẫn String)
  Order _fromDoc(Map<String, dynamic> data, String docId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final itemsList = (data['items'] as List?) ?? [];
    return Order(
      id: docId,
      userId: data['userId'] ?? '',
      items: itemsList
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0) is int
          ? data['totalAmount']
          : (data['totalAmount'] as num).toInt(),
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      paymentMethod: data['paymentMethod'] ?? 'cod',
      shippingAddress: Map<String, dynamic>.from(data['shippingAddress'] ?? {}),
      createdAt: parseDate(data['createdAt']),
      updatedAt:
          data['updatedAt'] != null ? parseDate(data['updatedAt']) : null,
    );
  }

  /// Lấy danh sách đơn hàng của user (1 lần)
  Future<List<Order>> getOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => _fromDoc(doc.data(), doc.id)).toList();
    } catch (e) {
      // Nếu index chưa tạo, fallback không orderBy
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      final orders =
          snapshot.docs.map((doc) => _fromDoc(doc.data(), doc.id)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    }
  }

  /// Real-time stream đơn hàng của user
  Stream<List<Order>> listenOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders =
          snapshot.docs.map((doc) => _fromDoc(doc.data(), doc.id)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Tạo đơn hàng mới
  Future<String> createOrder(Order order) async {
    try {
      final docRef = _firestore.collection('orders').doc(order.id);

      await docRef.set({
        ...order.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return order.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Hủy đơn hàng
  Future<void> cancelOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
