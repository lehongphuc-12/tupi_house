class Product {
  final String id;
  final String title;
  final int price;
  final int? salePrice;
  final String thumbnail;
  final List<String> images;
  final String description;
  final String categoryId;
  final String categoryName;
  final Map<String, dynamic> metaInfo;
  final int stock;
  final double rating;
  final int sold;

  Product({
    required this.id,
    required this.title,
    required this.price,
    this.salePrice,
    required this.thumbnail,
    required this.images,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.metaInfo = const {},
    this.stock = 0,
    this.rating = 0.0,
    this.sold = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] ?? 0,
      salePrice: json['salePrice'],
      thumbnail: json['thumbnail'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      metaInfo: json['meta_info'] ?? {},
      stock: json['stock'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      sold: json['sold'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'salePrice': salePrice,
      'thumbnail': thumbnail,
      'images': images,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'meta_info': metaInfo,
      'stock': stock,
      'rating': rating,
      'sold': sold,
    };
  }

  bool get isOnSale => salePrice != null && salePrice! < price;
}
