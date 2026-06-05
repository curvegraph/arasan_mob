enum DiscountType { percentage, flat }

class Offer {
  final String id;
  final String title;
  final String? description;
  final String productId;
  final String productName;
  final DiscountType discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  Offer({
    required this.id,
    required this.title,
    this.description,
    required this.productId,
    required this.productName,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Offer copyWith({
    String? title,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Offer(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      productId: productId,
      productName: productName,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  String get discountLabel {
    if (discountType == DiscountType.percentage) {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    return '₹${discountValue.toStringAsFixed(0)} OFF';
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    final productsData = json['products'];
    final productName = productsData is Map<String, dynamic>
        ? (productsData['name'] as String? ?? 'Unknown Product')
        : 'Unknown Product';

    return Offer(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      productId: json['product_id'] as String,
      productName: productName,
      discountType: (json['discount_type'] as String) == 'percentage'
          ? DiscountType.percentage
          : DiscountType.flat,
      discountValue: (json['discount_value'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

class Coupon {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Coupon copyWith({
    String? code,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    double? minOrderAmount,
    double? maxDiscount,
    int? usageLimit,
    int? usedCount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Coupon(
      id: id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isLimitReached => usageLimit != null && usedCount >= usageLimit!;

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String? ?? '',
      discountType: (json['discount_type'] as String) == 'percentage'
          ? DiscountType.percentage
          : DiscountType.flat,
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderAmount: json['min_order_amount'] != null
          ? (json['min_order_amount'] as num).toDouble()
          : null,
      maxDiscount: json['max_discount'] != null
          ? (json['max_discount'] as num).toDouble()
          : null,
      usageLimit: json['usage_limit'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
