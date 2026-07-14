// Cart Item
class CartItem {
  final String productId;
  final String title;
  final int price;
  final String thumbnail;
  final String? color;
  final String? size;
  final int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.thumbnail,
    this.color,
    this.size,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] ?? 0,
      thumbnail: json['thumbnail'] ?? '',
      color: json['color'],
      size: json['size'],
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'thumbnail': thumbnail,
      'color': color,
      'size': size,
      'quantity': quantity,
    };
  }
}

// Cart
class Cart {
  final String userId;
  final List<CartItem> items;

  Cart({required this.userId, List<CartItem>? items}) : items = items ?? [];

  int get totalItems => items.length;

  int get totalPrice =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return Cart(
      userId: json['userId'] ?? '',
      items: itemsList.map((item) => CartItem.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
