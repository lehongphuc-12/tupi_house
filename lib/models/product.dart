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
  final bool isFlashSale;
  final int? flashSalePrice;
  final DateTime? flashSaleStartTime;
  final DateTime? flashSaleEndTime;

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
    this.isFlashSale = false,
    this.flashSalePrice,
    this.flashSaleStartTime,
    this.flashSaleEndTime,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.tryParse(value.toString());
    }

    final parsedPrice = int.tryParse(json['price']?.toString() ?? '') ?? 0;
    final parsedSalePrice = json['salePrice'] != null
        ? int.tryParse(json['salePrice']?.toString() ?? '')
        : null;
    final parsedStock = int.tryParse(json['stock']?.toString() ?? '') ?? 0;
    final parsedRating = double.tryParse(json['rating']?.toString() ?? '') ?? 0.0;
    final parsedSold = int.tryParse(json['sold']?.toString() ?? '') ?? 0;
    final parsedFlashSalePrice = json['flashSalePrice'] != null
        ? int.tryParse(json['flashSalePrice']?.toString() ?? '')
        : null;

    return Product(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: parsedPrice,
      salePrice: parsedSalePrice,
      thumbnail: json['thumbnail'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      metaInfo: json['meta_info'] ?? {},
      stock: parsedStock,
      rating: parsedRating,
      sold: parsedSold,
      isFlashSale: json['isFlashSale'] ?? false,
      flashSalePrice: parsedFlashSalePrice,
      flashSaleStartTime: parseDate(json['flashSaleStartTime']),
      flashSaleEndTime: parseDate(json['flashSaleEndTime']),
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
      'isFlashSale': isFlashSale,
      'flashSalePrice': flashSalePrice,
      'flashSaleStartTime': flashSaleStartTime?.toIso8601String(),
      'flashSaleEndTime': flashSaleEndTime?.toIso8601String(),
    };
  }

  bool get isOnSale => salePrice != null && salePrice! < price;

  bool get isCurrentlyFlashSale {
    if (!isFlashSale || flashSalePrice == null) return false;
    final now = DateTime.now();
    if (flashSaleStartTime != null && now.isBefore(flashSaleStartTime!)) return false;
    if (flashSaleEndTime != null && now.isAfter(flashSaleEndTime!)) return false;
    return true;
  }
}

