class WishlistItem {
  final String productId;
  final String title;
  final int price;
  final String thumbnail;
  final String categoryName;
  final DateTime addedAt;

  WishlistItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.categoryName,
    required this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] ?? 0,
      thumbnail: json['thumbnail'] ?? '',
      categoryName: json['categoryName'] ?? '',
      addedAt: DateTime.parse(
        json['addedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'thumbnail': thumbnail,
      'categoryName': categoryName,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

class Wishlist {
  final String userId;
  final List<WishlistItem> items;

  Wishlist({required this.userId, List<WishlistItem>? items})
    : items = items ?? [];

  int get totalItems => items.length;

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    return Wishlist(
      userId: json['userId'] ?? '',
      items: itemsList.map((item) => WishlistItem.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods
  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  Wishlist copyWith({List<WishlistItem>? items}) {
    return Wishlist(userId: userId, items: items ?? this.items);
  }
}
