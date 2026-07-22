import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import 'notification_service.dart';

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
      subtotalAmount: (data['subtotalAmount'] ?? data['totalAmount'] ?? 0) is int
          ? (data['subtotalAmount'] ?? data['totalAmount'] ?? 0)
          : (data['subtotalAmount'] ?? data['totalAmount'] ?? 0 as num).toInt(),
      discountAmount: (data['discountAmount'] ?? 0) is int
          ? (data['discountAmount'] ?? 0)
          : (data['discountAmount'] ?? 0 as num).toInt(),
      shippingFee: (data['shippingFee'] ?? 30000) is int
          ? (data['shippingFee'] ?? 30000)
          : (data['shippingFee'] ?? 30000 as num).toInt(),
      totalAmount: (data['totalAmount'] ?? 0) is int
          ? data['totalAmount']
          : (data['totalAmount'] as num).toInt(),
      voucherCode: data['voucherCode']?.toString(),
      pointsUsed: (data['pointsUsed'] ?? 0) is int
          ? (data['pointsUsed'] ?? 0)
          : (data['pointsUsed'] ?? 0 as num).toInt(),
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
      final batch = _firestore.batch();
      final docRef = _firestore.collection('orders').doc(order.id);

      batch.set(docRef, {
        ...order.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Trừ kho hàng & tăng số lượng bán của từng sản phẩm
      for (final item in order.items) {
        final productRef = _firestore.collection('products').doc(item.productId);
        batch.update(productRef, {
          'stock': FieldValue.increment(-item.quantity),
          'sold': FieldValue.increment(item.quantity),
        });
      }

      await batch.commit();

      // In-app + push (via Cloud Function on notifications create)
      try {
        await NotificationService.notifyOrderCreated(
          userId: order.userId,
          orderId: order.id,
        );
      } catch (_) {
        // Don't fail checkout if notification write fails
      }

      return order.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Hủy đơn hàng
  Future<void> cancelOrder(String orderId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    
    final doc = await orderRef.get();
    if (!doc.exists) return;
    
    final data = doc.data() ?? {};
    final userId = data['userId']?.toString() ?? '';
    final currentStatus = data['status']?.toString() ?? 'pending';
    if (currentStatus == 'cancelled') return;

    final batch = _firestore.batch();
    batch.update(orderRef, {
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Hoàn trả kho hàng
    final itemsList = (data['items'] as List?) ?? [];
    for (final item in itemsList) {
      final productId = item['productId']?.toString() ?? '';
      final quantity = (item['quantity'] ?? 0) as int;
      if (productId.isNotEmpty && quantity > 0) {
        final productRef = _firestore.collection('products').doc(productId);
        batch.update(productRef, {
          'stock': FieldValue.increment(quantity),
          'sold': FieldValue.increment(-quantity),
        });
      }
    }

    await batch.commit();

    if (userId.isNotEmpty) {
      try {
        await NotificationService.notifyOrderStatusChanged(
          userId: userId,
          orderId: orderId,
          newStatus: 'cancelled',
        );
      } catch (_) {}
    }
  }
}
