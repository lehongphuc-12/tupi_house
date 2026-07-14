class Category {
  final String id;
  final String name;
  final String image;
  final String description;
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.image,
    this.description = '',
    this.order = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'order': order,
    };
  }
}
