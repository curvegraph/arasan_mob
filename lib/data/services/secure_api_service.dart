import 'api_service.dart';

/// Secure API Service — calls the Express backend for sensitive business logic
/// (price calculation, coupon validation, payments, reviews, cart sync, tracking).
class SecureApiService {
  final ApiService _api = ApiService();

  // Singleton
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal();

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : Map<String, dynamic>.from(value as Map);

  // ========================================
  // PAYMENT — Razorpay
  // ========================================

  Future<Map<String, dynamic>> createRazorpayOrder({
    required List<Map<String, dynamic>> items,
    String? couponCode,
    String deliveryOption = 'standard',
  }) async {
    final res = await _api.post('/payments/create-order',
        body: {
          'items': items,
          'couponCode': couponCode,
          'deliveryOption': deliveryOption,
        },
        requireAuth: true);
    return _asMap(res);
  }

  Future<Map<String, dynamic>> verifyRazorpayAndCreateOrder({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required List<Map<String, dynamic>> items,
    required String shippingAddressLine1,
    required String shippingCity,
    required String shippingState,
    required String shippingPincode,
    required String paymentMethod,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? couponCode,
    String deliveryOption = 'standard',
    String? notes,
  }) async {
    final res = await _api.post('/payments/verify',
        body: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
          'items': items,
          'customerName': customerName,
          'customerEmail': customerEmail,
          'customerPhone': customerPhone,
          'shippingAddress': {
            'line1': shippingAddressLine1,
            'city': shippingCity,
            'state': shippingState,
            'pincode': shippingPincode,
          },
          'paymentMethod': paymentMethod,
          'couponCode': couponCode,
          'deliveryOption': deliveryOption,
          'notes': notes,
        },
        requireAuth: true);
    return _asMap(res);
  }

  // ========================================
  // ORDER — COD
  // ========================================

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String shippingAddressLine1,
    required String shippingCity,
    required String shippingState,
    required String shippingPincode,
    required String paymentMethod,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? paymentId,
    String? couponCode,
    String deliveryOption = 'standard',
    String? notes,
  }) async {
    final res = await _api.post('/payments/cod-order',
        body: {
          'items': items,
          'customerName': customerName,
          'customerEmail': customerEmail,
          'customerPhone': customerPhone,
          'shippingAddress': {
            'line1': shippingAddressLine1,
            'city': shippingCity,
            'state': shippingState,
            'pincode': shippingPincode,
          },
          'paymentMethod': paymentMethod,
          'paymentId': paymentId,
          'couponCode': couponCode,
          'deliveryOption': deliveryOption,
          'notes': notes,
        },
        requireAuth: true);
    return _asMap(res);
  }

  // ========================================
  // COUPON — Server-side validation
  // ========================================

  Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    required double subtotal,
  }) async {
    final res = await _api.post('/coupons/validate',
        body: {'code': couponCode, 'cartTotal': subtotal});
    return _asMap(res);
  }

  // ========================================
  // REVIEW — Server-side persistence
  // ========================================

  Future<Map<String, dynamic>> submitReview({
    required String productId,
    required int rating,
    String? review,
  }) async {
    final res = await _api.post('/reviews/product/$productId',
        body: {
          'rating': rating,
          if (review != null) 'review': review,
        },
        requireAuth: true);
    return _asMap(res);
  }

  // ========================================
  // CART — Server-side persistence
  // ========================================

  Future<Map<String, dynamic>> syncCart(
    List<Map<String, dynamic>> items,
  ) async {
    final res = await _api.post('/cart/sync',
        body: {'items': items}, requireAuth: true);
    return _asMap(res);
  }

  Future<Map<String, dynamic>> getCart() async {
    final res = await _api.get('/cart', requireAuth: true);
    return _asMap(res);
  }

  // ========================================
  // SHIPROCKET — Tracking
  // ========================================

  Future<Map<String, dynamic>> trackShipment(String awb) async {
    final res = await _api.get('/shiprocket/track/$awb');
    return _asMap(res);
  }
}

class SecureApiException implements Exception {
  final String message;
  final int statusCode;
  SecureApiException(this.message, this.statusCode);

  @override
  String toString() => 'SecureApiException($statusCode): $message';
}
