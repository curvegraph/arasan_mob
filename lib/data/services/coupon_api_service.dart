import 'api_service.dart';

class CouponApiService {
  final ApiService _api = ApiService();

  /// Get all active coupons
  Future<List<CouponInfo>> getActiveCoupons() async {
    final response = await _api.get('/coupons/active');
    return (response as List).map((c) => CouponInfo.fromJson(c)).toList();
  }

  /// Validate a coupon code with cart total
  /// Returns discount amount if valid
  Future<CouponValidationResult> validateCoupon({
    required String code,
    required double cartTotal,
  }) async {
    final response = await _api.post(
      '/coupons/validate',
      body: {
        'code': code,
        'cartTotal': cartTotal,
      },
    );

    return CouponValidationResult.fromJson(response);
  }
}

class CouponInfo {
  final String id;
  final String code;
  final String? description;
  final String discountType; // 'percentage' or 'flat'
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscount;
  final DateTime? endDate;

  CouponInfo({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscount,
    this.endDate,
  });

  factory CouponInfo.fromJson(Map<String, dynamic> json) {
    return CouponInfo(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderAmount: json['min_order_amount'] != null
          ? (json['min_order_amount'] as num).toDouble()
          : null,
      maxDiscount: json['max_discount'] != null
          ? (json['max_discount'] as num).toDouble()
          : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }

  String get formattedDiscount {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}% OFF';
    }
    return '₹${discountValue.toInt()} OFF';
  }

  bool get isExpired {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }
}

class CouponValidationResult {
  final CouponDetails coupon;
  final double discount;

  CouponValidationResult({
    required this.coupon,
    required this.discount,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    return CouponValidationResult(
      coupon: CouponDetails.fromJson(json['coupon']),
      discount: (json['discount'] as num).toDouble(),
    );
  }
}

class CouponDetails {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;

  CouponDetails({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
  });

  factory CouponDetails.fromJson(Map<String, dynamic> json) {
    return CouponDetails(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      discountType: json['discountType'],
      discountValue: (json['discountValue'] as num).toDouble(),
    );
  }
}
