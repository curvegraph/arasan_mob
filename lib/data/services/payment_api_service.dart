import 'api_service.dart';

class PaymentApiService {
  final ApiService _api = ApiService();

  /// Create a Razorpay order for payment
  /// Returns orderId, amount, currency, and order summary
  Future<PaymentOrderResponse> createPaymentOrder({
    required List<CartItemRequest> items,
    String? couponCode,
    String deliveryOption = 'standard',
  }) async {
    final response = await _api.post(
      '/payments/create-order',
      body: {
        'items': items.map((i) => i.toJson()).toList(),
        if (couponCode != null) 'couponCode': couponCode,
        'deliveryOption': deliveryOption,
      },
      requireAuth: true,
    );

    return PaymentOrderResponse.fromJson(response);
  }

  /// Verify payment after Razorpay success
  /// Creates the order after verification
  Future<OrderCreatedResponse> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required List<CartItemRequest> items,
    String? couponCode,
    String deliveryOption = 'standard',
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required ShippingAddressRequest shippingAddress,
  }) async {
    final response = await _api.post(
      '/payments/verify',
      body: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'items': items.map((i) => i.toJson()).toList(),
        if (couponCode != null) 'couponCode': couponCode,
        'deliveryOption': deliveryOption,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'shippingAddress': shippingAddress.toJson(),
      },
      requireAuth: true,
    );

    return OrderCreatedResponse.fromJson(response);
  }

  /// Create a COD order (no payment required)
  Future<OrderCreatedResponse> createCodOrder({
    required List<CartItemRequest> items,
    String? couponCode,
    String deliveryOption = 'standard',
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required ShippingAddressRequest shippingAddress,
  }) async {
    final response = await _api.post(
      '/payments/cod-order',
      body: {
        'items': items.map((i) => i.toJson()).toList(),
        if (couponCode != null) 'couponCode': couponCode,
        'deliveryOption': deliveryOption,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'shippingAddress': shippingAddress.toJson(),
      },
      requireAuth: true,
    );

    return OrderCreatedResponse.fromJson(response);
  }

  /// Get payment status
  Future<PaymentStatus> getPaymentStatus(String paymentId) async {
    final response = await _api.get(
      '/payments/status/$paymentId',
      requireAuth: true,
    );

    return PaymentStatus.fromJson(response);
  }
}

// Request/Response classes

class CartItemRequest {
  final String productId;
  final int quantity;

  CartItemRequest({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

class ShippingAddressRequest {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;

  ShippingAddressRequest({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
  });

  Map<String, dynamic> toJson() => {
    'line1': line1,
    if (line2 != null) 'line2': line2,
    'city': city,
    'state': state,
    'pincode': pincode,
  };
}

class PaymentOrderResponse {
  final String razorpayOrderId;
  final int amount; // in paise
  final String currency;
  final OrderSummary orderSummary;

  PaymentOrderResponse({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.orderSummary,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    return PaymentOrderResponse(
      razorpayOrderId: json['razorpayOrderId'],
      amount: json['amount'],
      currency: json['currency'],
      orderSummary: OrderSummary.fromJson(json['orderSummary']),
    );
  }
}

class OrderSummary {
  final double subtotal;
  final double taxAmount;
  final double deliveryCharge;
  final double couponDiscount;
  final double total;

  OrderSummary({
    required this.subtotal,
    required this.taxAmount,
    required this.deliveryCharge,
    required this.couponDiscount,
    required this.total,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num).toDouble(),
      couponDiscount: (json['couponDiscount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class OrderCreatedResponse {
  final String orderId;
  final String orderNumber;
  final double total;
  final String paymentStatus;

  OrderCreatedResponse({
    required this.orderId,
    required this.orderNumber,
    required this.total,
    required this.paymentStatus,
  });

  factory OrderCreatedResponse.fromJson(Map<String, dynamic> json) {
    return OrderCreatedResponse(
      orderId: json['orderId'],
      orderNumber: json['orderNumber'],
      total: (json['total'] as num).toDouble(),
      paymentStatus: json['paymentStatus'],
    );
  }
}

class PaymentStatus {
  final String paymentId;
  final String status;
  final String method;
  final double amount;
  final String currency;

  PaymentStatus({
    required this.paymentId,
    required this.status,
    required this.method,
    required this.amount,
    required this.currency,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      paymentId: json['paymentId'],
      status: json['status'],
      method: json['method'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
    );
  }
}
