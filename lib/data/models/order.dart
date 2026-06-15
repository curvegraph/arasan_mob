enum OrderStatus { pending, confirmed, shipped, outForDelivery, delivered, cancelled, returned }

class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      imageUrl: json['product_image'] as String? ?? '',
      quantity: json['quantity'] as int,
      price: (json['unit_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson(String orderId) {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': imageUrl,
      'quantity': quantity,
      'unit_price': price,
      'total_price': total,
    };
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;
  final String? shippingAddressLine1;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPincode;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final OrderStatus status;
  final String? trackingId;
  final String paymentMethod;
  final bool isPaid;
  final String? couponCode;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final String? returnReason;

  Order({
    required this.id,
    String? orderNumber,
    required this.customerId,
    required this.customerName,
    this.customerEmail = '',
    required this.customerPhone,
    required this.shippingAddress,
    this.shippingAddressLine1,
    this.shippingCity,
    this.shippingState,
    this.shippingPincode,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.taxAmount,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.status,
    this.trackingId,
    required this.paymentMethod,
    required this.isPaid,
    this.couponCode,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
    this.returnReason,
  }) : orderNumber = orderNumber ?? id;

  Order copyWith({
    OrderStatus? status,
    String? trackingId,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancelReason,
    String? returnReason,
    String? notes,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      shippingAddress: shippingAddress,
      shippingAddressLine1: shippingAddressLine1,
      shippingCity: shippingCity,
      shippingState: shippingState,
      shippingPincode: shippingPincode,
      items: items,
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      status: status ?? this.status,
      trackingId: trackingId ?? this.trackingId,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      couponCode: couponCode,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      returnReason: returnReason ?? this.returnReason,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  // JSON Serialization for Supabase
  factory Order.fromJson(Map<String, dynamic> json, List<OrderItem> items) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      customerEmail: json['customer_email'] as String? ?? '',
      customerPhone: json['customer_phone'] as String,
      // Join only the parts that are actually present, so a missing field
      // doesn't leave stray punctuation (", ,  - ") that renders as a blank box.
      shippingAddress: [
        (json['shipping_address_line1'] ?? '').toString().trim(),
        (json['shipping_address_line2'] ?? '').toString().trim(),
        (json['shipping_city'] ?? '').toString().trim(),
        (json['shipping_state'] ?? '').toString().trim(),
        (json['shipping_pincode'] ?? '').toString().trim(),
      ].where((p) => p.isNotEmpty).join(', '),
      shippingAddressLine1: json['shipping_address_line1'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingState: json['shipping_state'] as String?,
      shippingPincode: json['shipping_pincode'] as String?,
      items: items,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: _parseStatus(json['status'] as String?),
      trackingId: json['awb'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'upi',
      isPaid: json['payment_status'] == 'paid',
      couponCode: json['coupon_code'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at']) : null,
      shippedAt: json['shipped_at'] != null ? DateTime.parse(json['shipped_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      cancelReason: json['cancel_reason'] as String?,
      returnReason: json['return_reason'] as String?,
    );
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.confirmed;
      case 'shipped':
      case 'in_transit':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'rto':
        return OrderStatus.cancelled;
      case 'return_requested':
      case 'returned':
        return OrderStatus.returned;
      default:
        return OrderStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'shipping_address_line1': shippingAddressLine1 ?? shippingAddress,
      'shipping_city': shippingCity ?? '',
      'shipping_state': shippingState ?? '',
      'shipping_pincode': shippingPincode ?? '',
      'subtotal': subtotal,
      'delivery_charge': deliveryCharge,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'status': 'confirmed',
      'payment_method': paymentMethod,
      'payment_status': isPaid ? 'paid' : 'pending',
      'coupon_code': couponCode,
      'notes': notes,
    };
  }
}
