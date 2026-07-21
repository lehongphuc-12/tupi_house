class Voucher {
  final String id;
  final String code;
  final String description;
  final int discountPercent;
  final int minimumOrder;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const Voucher({
    required this.id,
    required this.code,
    this.description = '',
    required this.discountPercent,
    this.minimumOrder = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return Voucher(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountPercent: (json['discountPercent'] as num? ?? 0).toInt(),
      minimumOrder: (json['minimumOrder'] as num? ?? 0).toInt(),
      startDate: parse(json['startDate']),
      endDate: parse(json['endDate']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code.trim().toUpperCase(),
        'description': description.trim(),
        'discountPercent': discountPercent,
        'minimumOrder': minimumOrder,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': isActive,
      };
}
