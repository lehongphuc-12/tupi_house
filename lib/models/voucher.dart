class Voucher {
  final String id;
  final String code;
  final String description;
  final int discountPercent;
  final int minimumOrder;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String type; // "percent" | "fixed"
  final int discountValue;
  final int minOrderValue;
  final int? maxDiscountAmount;
  final int usageLimit;
  final int usedCount;

  const Voucher({
    required this.id,
    required this.code,
    this.description = '',
    required this.discountPercent,
    this.minimumOrder = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.type = 'percent',
    this.discountValue = 0,
    this.minOrderValue = 0,
    this.maxDiscountAmount,
    this.usageLimit = 9999,
    this.usedCount = 0,
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

    final discPercent = int.tryParse(json['discountPercent']?.toString() ?? '') ?? 0;
    final discVal = int.tryParse(json['discountValue']?.toString() ?? json['discountPercent']?.toString() ?? '') ?? 0;
    final minOrdVal = int.tryParse(json['minOrderValue']?.toString() ?? json['minimumOrder']?.toString() ?? '') ?? 0;
    final maxDisc = json['maxDiscountAmount'] != null
        ? (int.tryParse(json['maxDiscountAmount']?.toString() ?? '') ?? 0)
        : null;
    final limit = int.tryParse(json['usageLimit']?.toString() ?? '') ?? 9999;
    final used = int.tryParse(json['usedCount']?.toString() ?? '') ?? 0;

    return Voucher(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountPercent: discPercent,
      minimumOrder: minOrdVal,
      startDate: parse(json['startDate']),
      endDate: parse(json['endDate']),
      isActive: json['isActive'] ?? true,
      type: json['type'] ?? 'percent',
      discountValue: discVal,
      minOrderValue: minOrdVal,
      maxDiscountAmount: maxDisc,
      usageLimit: limit,
      usedCount: used,
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
        'type': type,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
        'maxDiscountAmount': maxDiscountAmount,
        'usageLimit': usageLimit,
        'usedCount': usedCount,
      };
}

