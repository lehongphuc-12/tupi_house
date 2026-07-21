import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/voucher.dart';
import '../services/notification_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  String? errorMessage;
  List<Category> categories = [];
  List<Product> products = [];
  List<Order> orders = [];
  List<AppUser> users = [];
  List<Voucher> vouchers = [];

  int get revenue => orders
      .where((order) => order.status == 'delivered')
      .fold(0, (sum, order) => sum + order.totalAmount);

  static const List<String> validOrderStatuses = [
    'pending',
    'confirmed',
    'shipping',
    'delivered',
    'cancelled',
  ];

  String normalizeOrderStatus(String status) {
    final normalized = status.trim().toLowerCase();

    if (validOrderStatuses.contains(normalized)) {
      return normalized;
    }

    return 'pending';
  }

  List<String> getAllowedNextOrderStatuses(String currentStatus) {
    switch (normalizeOrderStatus(currentStatus)) {
      case 'pending':
        return ['confirmed', 'cancelled'];

      case 'confirmed':
        return ['shipping', 'cancelled'];

      case 'shipping':
        return ['delivered'];

      case 'delivered':
      case 'cancelled':
        return [];

      default:
        return [];
    }
  }

  bool canUpdateOrderStatus({
    required String currentStatus,
    required String newStatus,
  }) {
    final current = normalizeOrderStatus(currentStatus);
    final next = normalizeOrderStatus(newStatus);

    return getAllowedNextOrderStatuses(current).contains(next);
  }

  String orderStatusLabel(String status) {
    switch (normalizeOrderStatus(status)) {
      case 'pending':
        return 'Chờ xác nhận';

      case 'confirmed':
        return 'Đã xác nhận';

      case 'shipping':
        return 'Đang giao';

      case 'delivered':
        return 'Đã giao';

      case 'cancelled':
        return 'Đã hủy';

      default:
        return 'Không xác định';
    }
  }

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([
        loadCategories(notify: false),
        loadProducts(notify: false),
        loadOrders(notify: false),
        loadUsers(notify: false),
        loadVouchers(notify: false),
      ]);
    } catch (e) {
      errorMessage = 'Không thể tải dữ liệu quản trị: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories({bool notify = true}) async {
    final snapshot = await _db.collection('categories').get();
    categories = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Category.fromJson(data);
    }).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    if (notify) notifyListeners();
  }

  Future<void> saveCategory(Category category) async {
    final ref = category.id.isEmpty
        ? _db.collection('categories').doc()
        : _db.collection('categories').doc(category.id);
    await ref.set(Category(
      id: ref.id,
      name: category.name.trim(),
      image: category.image.trim(),
      description: category.description.trim(),
      order: category.order,
    ).toJson());
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    final used = await _db
        .collection('products')
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();
    if (used.docs.isNotEmpty) {
      throw Exception('Danh mục đang được sản phẩm sử dụng.');
    }
    await _db.collection('categories').doc(id).delete();
    await loadCategories();
  }

  Future<void> loadProducts({bool notify = true}) async {
    final snapshot = await _db.collection('products').get();
    products = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    if (notify) notifyListeners();
  }

  Future<void> saveProduct(Product product) async {
    final ref = product.id.isEmpty
        ? _db.collection('products').doc()
        : _db.collection('products').doc(product.id);
    final data = product.toJson();
    data['id'] = ref.id;
    await ref.set(data);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
    await loadProducts();
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Future<void> loadOrders({bool notify = true}) async {
    final snapshot = await _db.collection('orders').get();
    orders = snapshot.docs.map((doc) {
      final data = doc.data();
      final items = (data['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return Order(
        id: doc.id,
        userId: data['userId'] ?? '',
        items: items,
        totalAmount: (data['totalAmount'] as num? ?? 0).toInt(),
        status: data['status'] ?? 'pending',
        paymentStatus: data['paymentStatus'] ?? 'unpaid',
        paymentMethod: data['paymentMethod'] ?? 'cod',
        shippingAddress:
            Map<String, dynamic>.from(data['shippingAddress'] ?? {}),
        createdAt: _parseDate(data['createdAt']),
        updatedAt:
            data['updatedAt'] == null ? null : _parseDate(data['updatedAt']),
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (notify) notifyListeners();
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final normalizedNewStatus = newStatus.trim().toLowerCase();

    if (!validOrderStatuses.contains(normalizedNewStatus)) {
      throw Exception('Trạng thái đơn hàng không hợp lệ.');
    }

    String? notifyUserId;

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw Exception('Không tìm thấy đơn hàng.');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('Dữ liệu đơn hàng không hợp lệ.');
      }

      final currentStatus = normalizeOrderStatus(
        data['status']?.toString() ?? 'pending',
      );

      if (currentStatus == normalizedNewStatus) {
        return;
      }

      final isAllowed = canUpdateOrderStatus(
        currentStatus: currentStatus,
        newStatus: normalizedNewStatus,
      );

      if (!isAllowed) {
        throw Exception(
          'Không thể chuyển đơn hàng từ '
          '"${orderStatusLabel(currentStatus)}" sang '
          '"${orderStatusLabel(normalizedNewStatus)}".',
        );
      }

      transaction.update(orderRef, {
        'status': normalizedNewStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyUserId = data['userId']?.toString();
    });

    // Notify customer only when status actually changed
    if (notifyUserId != null && notifyUserId!.isNotEmpty) {
      try {
        await NotificationService.notifyOrderStatusChanged(
          userId: notifyUserId!,
          orderId: orderId,
          newStatus: normalizedNewStatus,
        );
      } catch (_) {
        // Order update already succeeded; notification is best-effort.
      }
    }

    await loadOrders();
  }

  Future<void> loadUsers({bool notify = true}) async {
    final snapshot = await _db.collection('users').get();
    users = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return AppUser.fromJson(data);
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (notify) notifyListeners();
  }

  Future<void> updateUserAdminFields(String id,
      {required String role, required bool isActive}) async {
    await _db.collection('users').doc(id).set({
      'role': role,
      'isActive': isActive,
    }, SetOptions(merge: true));
    await loadUsers();
  }

  Future<Map<String, dynamic>> getUserAdminFields(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    final data = doc.data() ?? {};
    return {
      'role': data['role'] ?? 'user',
      'isActive': data['isActive'] ?? true
    };
  }

  Future<void> loadVouchers({bool notify = true}) async {
    final snapshot = await _db.collection('vouchers').get();
    vouchers = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Voucher.fromJson(data);
    }).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    if (notify) notifyListeners();
  }

  Future<void> saveVoucher(Voucher voucher) async {
    final ref = voucher.id.isEmpty
        ? _db.collection('vouchers').doc()
        : _db.collection('vouchers').doc(voucher.id);
    final data = Voucher(
      id: ref.id,
      code: voucher.code,
      description: voucher.description,
      discountPercent: voucher.discountPercent,
      minimumOrder: voucher.minimumOrder,
      startDate: voucher.startDate,
      endDate: voucher.endDate,
      isActive: voucher.isActive,
    ).toJson();
    await ref.set(data);
    await loadVouchers();
  }

  Future<void> deleteVoucher(String id) async {
    await _db.collection('vouchers').doc(id).delete();
    await loadVouchers();
  }
}
