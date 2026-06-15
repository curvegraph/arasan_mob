import 'api_service.dart';
import 'payment_api_service.dart';

class OrderApiService {
  final ApiService _api = ApiService();

  /// Place a new order
  Future<PlaceOrderResponse> placeOrder({
    required List<CartItemRequest> items,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    required ShippingAddressRequest shippingAddress,
    required String paymentMethod,
    String? couponCode,
    bool isPaid = false,
    String? razorpayOrderId,
    String? paymentId,
  }) async {
    final response = await _api.post(
      '/orders',
      body: {
        'items': items.map((i) => i.toJson()).toList(),
        if (customerName != null) 'customerName': customerName,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (customerPhone != null) 'customerPhone': customerPhone,
        'shippingAddress': shippingAddress.toJson(),
        'paymentMethod': paymentMethod,
        if (couponCode != null) 'couponCode': couponCode,
        'isPaid': isPaid,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        if (paymentId != null) 'paymentId': paymentId,
      },
      requireAuth: true,
    );

    return PlaceOrderResponse.fromJson(response);
  }

  /// Validate cart items and get server-calculated totals
  Future<CartValidationResponse> validateCart({
    required List<CartItemRequest> items,
    String? couponCode,
    String deliveryOption = 'standard',
  }) async {
    final response = await _api.post(
      '/orders/validate-cart',
      body: {
        'items': items.map((i) => i.toJson()).toList(),
        if (couponCode != null) 'couponCode': couponCode,
        'deliveryOption': deliveryOption,
      },
    );

    return CartValidationResponse.fromJson(response);
  }

  /// Get user's orders with pagination
  Future<OrdersListResponse> getMyOrders({int page = 1, int limit = 10}) async {
    final response = await _api.get(
      '/orders/my-orders',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      requireAuth: true,
    );

    return OrdersListResponse.fromJson(response);
  }

  /// Get single order details
  Future<OrderDetails> getOrderDetails(String orderId) async {
    final response = await _api.get(
      '/orders/my-orders/$orderId',
      requireAuth: true,
    );

    return OrderDetails.fromJson(response);
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _api.post(
      '/orders/my-orders/$orderId/cancel',
      body: {
        if (reason != null) 'reason': reason,
      },
      requireAuth: true,
    );
  }

  /// Request a return on a delivered order. Backend marks the order
  /// `return_requested`; admin reviews and approves/rejects via the admin app.
  Future<void> requestReturn(String orderId, {String? reason}) async {
    await _api.post(
      '/orders/my-orders/$orderId/return',
      body: {
        if (reason != null) 'reason': reason,
      },
      requireAuth: true,
    );
  }

  /// Track order shipping status
  Future<TrackingInfo> trackOrder(String orderId) async {
    final response = await _api.get(
      '/shiprocket/track-order/$orderId',
      requireAuth: true,
    );

    return TrackingInfo.fromJson(response);
  }
}

// Response classes

class CartValidationResponse {
  final List<ValidatedItem> items;
  final double subtotal;
  final double taxAmount;
  final double deliveryCharge;
  final double couponDiscount;
  final double total;

  CartValidationResponse({
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.deliveryCharge,
    required this.couponDiscount,
    required this.total,
  });

  factory CartValidationResponse.fromJson(Map<String, dynamic> json) {
    return CartValidationResponse(
      items: (json['items'] as List).map((i) => ValidatedItem.fromJson(i)).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num).toDouble(),
      couponDiscount: (json['couponDiscount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class ValidatedItem {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;

  ValidatedItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory ValidatedItem.fromJson(Map<String, dynamic> json) {
    return ValidatedItem(
      productId: json['productId'],
      name: json['name'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class OrdersListResponse {
  final List<OrderSummaryItem> orders;
  final OrderPagination pagination;

  OrdersListResponse({required this.orders, required this.pagination});

  factory OrdersListResponse.fromJson(Map<String, dynamic> json) {
    return OrdersListResponse(
      orders: (json['orders'] as List? ?? []).map((o) => OrderSummaryItem.fromJson(o)).toList(),
      pagination: OrderPagination.fromJson(json['pagination']),
    );
  }
}

class OrderSummaryItem {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final String customerName;
  final String customerPhone;
  final String shippingAddress;
  final List<OrderItemSummary> items;

  OrderSummaryItem({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    required this.items,
  });

  factory OrderSummaryItem.fromJson(Map<String, dynamic> json) {
    return OrderSummaryItem(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['payment_status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      // Built from the saved address parts (skipping any blanks) so the order
      // detail page can show the address the customer entered at checkout.
      shippingAddress: [
        (json['shipping_address_line1'] ?? '').toString().trim(),
        (json['shipping_address_line2'] ?? '').toString().trim(),
        (json['shipping_city'] ?? '').toString().trim(),
        (json['shipping_state'] ?? '').toString().trim(),
        (json['shipping_pincode'] ?? '').toString().trim(),
      ].where((p) => p.isNotEmpty).join(', '),
      items: (json['order_items'] as List? ?? []).map((i) => OrderItemSummary.fromJson(i)).toList(),
    );
  }
}

class OrderItemSummary {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  OrderItemSummary({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] ?? '',
      // Backend snapshots/backfills the product image onto each order item.
      imageUrl: json['product_image'] as String? ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderDetails {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddressLine1;
  final String? shippingAddressLine2;
  final String shippingCity;
  final String shippingState;
  final String shippingPincode;
  final double subtotal;
  final double taxAmount;
  final double deliveryCharge;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? couponCode;
  final String? awb;
  final String? courierName;
  final DateTime createdAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final List<OrderItemDetail> items;

  OrderDetails({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddressLine1,
    this.shippingAddressLine2,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingPincode,
    required this.subtotal,
    required this.taxAmount,
    required this.deliveryCharge,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.couponCode,
    this.awb,
    this.courierName,
    required this.createdAt,
    this.shippedAt,
    this.deliveredAt,
    required this.items,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['id'],
      orderNumber: json['order_number'],
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      shippingAddressLine1: json['shipping_address_line1'],
      shippingAddressLine2: json['shipping_address_line2'],
      shippingCity: json['shipping_city'],
      shippingState: json['shipping_state'],
      shippingPincode: json['shipping_pincode'],
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      deliveryCharge: (json['delivery_charge'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      status: json['status'],
      couponCode: json['coupon_code'],
      awb: json['awb'],
      courierName: json['courier_name'],
      createdAt: DateTime.parse(json['created_at']),
      shippedAt: json['shipped_at'] != null ? DateTime.parse(json['shipped_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      items: (json['order_items'] as List).map((i) => OrderItemDetail.fromJson(i)).toList(),
    );
  }
}

class OrderItemDetail {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItemDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}

class TrackingInfo {
  final String orderNumber;
  final String status;
  final String? awb;
  final String? courierName;
  final String currentStatus;
  final String? currentStatusDescription;
  final DateTime? deliveredDate;
  final List<TrackingEvent> trackingHistory;

  TrackingInfo({
    required this.orderNumber,
    required this.status,
    this.awb,
    this.courierName,
    required this.currentStatus,
    this.currentStatusDescription,
    this.deliveredDate,
    required this.trackingHistory,
  });

  factory TrackingInfo.fromJson(Map<String, dynamic> json) {
    return TrackingInfo(
      orderNumber: json['orderNumber'],
      status: json['status'],
      awb: json['awb'],
      courierName: json['courierName'],
      currentStatus: json['currentStatus'] ?? json['status'],
      currentStatusDescription: json['currentStatusDescription'],
      deliveredDate: json['deliveredDate'] != null ? DateTime.parse(json['deliveredDate']) : null,
      trackingHistory: (json['trackingHistory'] as List? ?? [])
          .map((t) => TrackingEvent.fromJson(t))
          .toList(),
    );
  }
}

class TrackingEvent {
  final String activity;
  final DateTime date;

  TrackingEvent({required this.activity, required this.date});

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      activity: json['activity'],
      date: DateTime.parse(json['date']),
    );
  }
}

class OrderPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  OrderPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory OrderPagination.fromJson(Map<String, dynamic> json) {
    return OrderPagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
    );
  }
}

// Request classes

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
  final String? deliveryOption;

  ShippingAddressRequest({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.deliveryOption,
  });

  Map<String, dynamic> toJson() => {
    'line1': line1,
    if (line2 != null) 'line2': line2,
    'city': city,
    'state': state,
    'pincode': pincode,
    if (deliveryOption != null) 'deliveryOption': deliveryOption,
  };
}

class PlaceOrderResponse {
  final String id;
  final String orderNumber;
  final double total;
  final String paymentStatus;
  final String status;

  PlaceOrderResponse({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.paymentStatus,
    required this.status,
  });

  factory PlaceOrderResponse.fromJson(Map<String, dynamic> json) {
    return PlaceOrderResponse(
      id: json['id'],
      orderNumber: json['orderNumber'],
      total: (json['total'] as num).toDouble(),
      paymentStatus: json['paymentStatus'],
      status: json['status'],
    );
  }
}
