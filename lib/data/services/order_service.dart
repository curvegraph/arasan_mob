import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  Order _toOrder(Map<String, dynamic> json) {
    final itemsJson = (json['order_items'] as List?) ?? const [];
    final items = itemsJson
        .whereType<Map>()
        .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return Order.fromJson(json, items);
  }

  /// Create a new order via the backend.
  Future<Order> createOrder({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddressLine1,
    required String shippingCity,
    required String shippingState,
    required String shippingPincode,
    required List<OrderItem> items,
    required double subtotal,
    required double deliveryCharge,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    required String paymentMethod,
    required bool isPaid,
    String? couponCode,
    String? notes,
  }) async {
    final body = {
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shippingAddressLine1': shippingAddressLine1,
      'shippingCity': shippingCity,
      'shippingState': shippingState,
      'shippingPincode': shippingPincode,
      'items': items.map((it) => {
            'productId': it.productId,
            'productName': it.productName,
            'imageUrl': it.imageUrl,
            'quantity': it.quantity,
            'price': it.price,
            'total': it.total,
          }).toList(),
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'couponCode': couponCode,
      'notes': notes,
    };
    final res = await _api.post('/orders', body: body, requireAuth: true);

    final orderMap = (res is Map && res['order'] is Map)
        ? Map<String, dynamic>.from(res['order'] as Map)
        : Map<String, dynamic>.from(res as Map);

    // Backend returns order without items; merge them in.
    if (orderMap['order_items'] == null) {
      orderMap['order_items'] = items.map((it) => {
            'product_id': it.productId,
            'product_name': it.productName,
            'product_image': it.imageUrl,
            'quantity': it.quantity,
            'unit_price': it.price,
            'total_price': it.total,
          }).toList();
    }
    return _toOrder(orderMap);
  }

  /// Get all orders for the current authenticated customer.
  Future<List<Order>> getOrdersByCustomer(String customerId) async {
    final data = await _api.get('/orders/my-orders', requireAuth: true,
        queryParams: {'limit': '500'});
    final list = (data is Map && data['orders'] is List)
        ? data['orders'] as List
        : (data is List ? data : const []);
    return list
        .whereType<Map>()
        .map((e) => _toOrder(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Order?> getOrderById(String id) async {
    try {
      final data = await _api.get('/orders/my-orders/$id', requireAuth: true);
      final m = (data is Map && data['order'] is Map)
          ? Map<String, dynamic>.from(data['order'] as Map)
          : Map<String, dynamic>.from(data as Map);
      return _toOrder(m);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Order?> getOrderByNumber(String orderNumber) async {
    try {
      final data = await _api.get('/orders/my-orders-by-number/$orderNumber',
          requireAuth: true);
      final m = (data is Map && data['order'] is Map)
          ? Map<String, dynamic>.from(data['order'] as Map)
          : Map<String, dynamic>.from(data as Map);
      return _toOrder(m);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _api.post('/orders/my-orders/$orderId/cancel',
        body: {'reason': reason}, requireAuth: true);
  }

  Future<void> requestReturn(String orderId, String reason) async {
    await _api.post('/orders/my-orders/$orderId/return',
        body: {'reason': reason}, requireAuth: true);
  }
}
