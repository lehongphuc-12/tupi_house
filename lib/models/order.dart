class OrderItem {
  final String productId;
  final String title;
  final int price;
  final int quantity;
  final String? color;
  final String? size;
  final String thumbnail;

  OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    this.color,
    this.size,
    required this.thumbnail,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 1,
      color: json['color'],
      size: json['size'],
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'color': color,
      'size': size,
      'thumbnail': thumbnail,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final int subtotalAmount;
  final int discountAmount;
  final int shippingFee;
  final int totalAmount;
  final String? voucherCode;
  final int pointsUsed;
  final String status; // pending, confirmed, shipping, delivered, cancelled
  final String paymentStatus; // paid, unpaid
  final String paymentMethod;
  final Map<String, dynamic> shippingAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    this.subtotalAmount = 0,
    this.discountAmount = 0,
    this.shippingFee = 30000,
    required this.totalAmount,
    this.voucherCode,
    this.pointsUsed = 0,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'cod',
    required this.shippingAddress,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return Order(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: itemsList.map((item) => OrderItem.fromJson(item)).toList(),
      subtotalAmount: (json['subtotalAmount'] ?? json['totalAmount'] ?? 0) is int
          ? (json['subtotalAmount'] ?? json['totalAmount'] ?? 0)
          : (json['subtotalAmount'] ?? json['totalAmount'] ?? 0 as num).toInt(),
      discountAmount: (json['discountAmount'] ?? 0) is int
          ? (json['discountAmount'] ?? 0)
          : (json['discountAmount'] ?? 0 as num).toInt(),
      shippingFee: (json['shippingFee'] ?? 30000) is int
          ? (json['shippingFee'] ?? 30000)
          : (json['shippingFee'] ?? 30000 as num).toInt(),
      totalAmount: json['totalAmount'] ?? 0,
      voucherCode: json['voucherCode'],
      pointsUsed: (json['pointsUsed'] ?? 0) is int
          ? (json['pointsUsed'] ?? 0)
          : (json['pointsUsed'] ?? 0 as num).toInt(),
      status: json['status'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      paymentMethod: json['paymentMethod'] ?? 'cod',
      shippingAddress: json['shippingAddress'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotalAmount': subtotalAmount,
      'discountAmount': discountAmount,
      'shippingFee': shippingFee,
      'totalAmount': totalAmount,
      'voucherCode': voucherCode,
      'pointsUsed': pointsUsed,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

