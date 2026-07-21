import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

/// Tạo 5 đơn hàng mẫu cho user (đủ mọi trạng thái để test)
class SeedOrders {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seed(String userId) async {
    final now = DateTime.now();

    final orders = [
      // ─── 1. PENDING ────────────────────────────────────────────
      {
        'userId': userId,
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'paymentMethod': 'cod',
        'totalAmount': 600000,
        'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'updatedAt': null,
        'shippingAddress': {
          'name': 'Nguyễn Văn A',
          'phone': '0901234567',
          'address': '123 Đường Lê Lợi, Quận 1, TP. Hồ Chí Minh',
        },
        'items': [
          {
            'productId': 'bb04-bup-bê-len-hand',
            'title': 'BB04 Búp Bê Len Handmade',
            'price': 320000,
            'quantity': 1,
            'color': 'Hồng',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021153/handmade-shop/qjfykwln5apg8dwthbrn.png',
          },
          {
            'productId': 'bb05-bup-bê-len-elli',
            'title': 'BB05 Búp Bê Len Ellie Handmade',
            'price': 280000,
            'quantity': 1,
            'color': 'Tím',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021173/handmade-shop/ryaaznppmm2gvl6godaj.png',
          },
        ],
      },

      // ─── 2. CONFIRMED ──────────────────────────────────────────
      {
        'userId': userId,
        'status': 'confirmed',
        'paymentStatus': 'unpaid',
        'paymentMethod': 'cod',
        'totalAmount': 320000,
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(hours: 20)).toIso8601String(),
        'shippingAddress': {
          'name': 'Trần Thị B',
          'phone': '0912345678',
          'address': '45 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
        },
        'items': [
          {
            'productId': 'bb06-bup-bê-len-luna',
            'title': 'BB06 Búp Bê Len Luna Handmade',
            'price': 320000,
            'quantity': 1,
            'color': 'Hồng',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021189/handmade-shop/p3bdhx1vufiktke4ryee.png',
          },
        ],
      },

      // ─── 3. SHIPPING ───────────────────────────────────────────
      {
        'userId': userId,
        'status': 'shipping',
        'paymentStatus': 'paid',
        'paymentMethod': 'bank',
        'totalAmount': 860000,
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'shippingAddress': {
          'name': 'Lê Văn C',
          'phone': '0923456789',
          'address': '78 Bà Triệu, Quận Hai Bà Trưng, Hà Nội',
        },
        'items': [
          {
            'productId': 'bb04-bup-bê-len-hand',
            'title': 'BB04 Búp Bê Len Handmade',
            'price': 320000,
            'quantity': 1,
            'color': 'Tím',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021153/handmade-shop/qjfykwln5apg8dwthbrn.png',
          },
          {
            'productId': 'bb06-bup-bê-len-luna',
            'title': 'BB06 Búp Bê Len Luna Handmade',
            'price': 320000,
            'quantity': 1,
            'color': 'Hồng',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021189/handmade-shop/p3bdhx1vufiktke4ryee.png',
          },
          {
            'productId': 'bb05-bup-bê-len-elli',
            'title': 'BB05 Búp Bê Len Ellie Handmade',
            'price': 280000,
            'quantity': 1,
            'color': 'Hồng',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021173/handmade-shop/ryaaznppmm2gvl6godaj.png',
          },
        ],
      },

      // ─── 4. DELIVERED ──────────────────────────────────────────
      {
        'userId': userId,
        'status': 'delivered',
        'paymentStatus': 'paid',
        'paymentMethod': 'momo',
        'totalAmount': 560000,
        'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(days: 4)).toIso8601String(),
        'shippingAddress': {
          'name': 'Phạm Thị D',
          'phone': '0934567890',
          'address': '12 Trần Phú, Hải Châu, Đà Nẵng',
        },
        'items': [
          {
            'productId': 'bb05-bup-bê-len-elli',
            'title': 'BB05 Búp Bê Len Ellie Handmade',
            'price': 280000,
            'quantity': 2,
            'color': 'Tím',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021173/handmade-shop/ryaaznppmm2gvl6godaj.png',
          },
        ],
      },

      // ─── 5. DELIVERED (thứ 2, đã đánh giá) ────────────────────
      {
        'userId': userId,
        'status': 'delivered',
        'paymentStatus': 'paid',
        'paymentMethod': 'cod',
        'totalAmount': 320000,
        'createdAt': now.subtract(const Duration(days: 14)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(days: 11)).toIso8601String(),
        'shippingAddress': {
          'name': 'Nguyễn Văn A',
          'phone': '0901234567',
          'address': '123 Đường Lê Lợi, Quận 1, TP. Hồ Chí Minh',
        },
        'items': [
          {
            'productId': 'bb04-bup-bê-len-hand',
            'title': 'BB04 Búp Bê Len Handmade',
            'price': 320000,
            'quantity': 1,
            'color': 'Hồng',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021153/handmade-shop/qjfykwln5apg8dwthbrn.png',
          },
        ],
      },

      // ─── 6. CANCELLED ──────────────────────────────────────────
      {
        'userId': userId,
        'status': 'cancelled',
        'paymentStatus': 'unpaid',
        'paymentMethod': 'cod',
        'totalAmount': 280000,
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'shippingAddress': {
          'name': 'Nguyễn Văn A',
          'phone': '0901234567',
          'address': '123 Đường Lê Lợi, Quận 1, TP. Hồ Chí Minh',
        },
        'items': [
          {
            'productId': 'bb05-bup-bê-len-elli',
            'title': 'BB05 Búp Bê Len Ellie Handmade',
            'price': 280000,
            'quantity': 1,
            'color': 'Hồng',
            'size': null,
            'thumbnail':
                'https://res.cloudinary.com/dsbhtgduv/image/upload/v1784021173/handmade-shop/ryaaznppmm2gvl6godaj.png',
          },
        ],
      },
    ];

    final batch = _db.batch();
    for (final order in orders) {
      final ref = _db.collection('orders').doc();
      batch.set(ref, order);
    }
    await batch.commit();
  }

  /// Xóa toàn bộ đơn hàng mẫu của user (để seed lại)
  static Future<void> clearUserOrders(String userId) async {
    final snapshot =
        await _db.collection('orders').where('userId', isEqualTo: userId).get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
