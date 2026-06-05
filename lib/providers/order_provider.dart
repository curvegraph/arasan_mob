import 'package:flutter/material.dart';
import '../data/models/order.dart';
import '../data/services/order_api_service.dart';
import '../data/services/payment_api_service.dart';

/// Legacy OrderProvider - delegates to OrderApiService for API integration.
/// Prefer using UserOrderProvider for full functionality.
class OrderProvider extends ChangeNotifier {
  final OrderApiService _orderApiService = OrderApiService();
  final PaymentApiService _paymentApiService = PaymentApiService();

  final List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  String? _razorpayOrderId;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get razorpayOrderId => _razorpayOrderId;

  /// Place order via API (creates payment order first)
  Future<Order> placeOrder({
    required List<OrderItem> items,
    required String shippingAddress,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
    required double subtotal,
    required double deliveryCharge,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    String? couponCode,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate cart items via API first
      final cartItems = items.map((item) => CartItemRequest(
        productId: item.productId,
        quantity: item.quantity,
      )).toList();

      final validation = await _orderApiService.validateCart(
        items: cartItems,
        couponCode: couponCode,
        deliveryOption: 'standard',
      );

      // Create payment order if not COD
      if (paymentMethod.toLowerCase() != 'cod') {
        final paymentOrder = await _paymentApiService.createPaymentOrder(
          items: cartItems,
          couponCode: couponCode,
          deliveryOption: 'standard',
        );
        _razorpayOrderId = paymentOrder.razorpayOrderId;
      }

      // Create local order object for immediate UI feedback
      final order = Order(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'ORD-PENDING',
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        shippingAddress: shippingAddress,
        items: items,
        subtotal: validation.subtotal,
        deliveryCharge: validation.deliveryCharge,
        taxAmount: validation.taxAmount,
        discountAmount: validation.couponDiscount,
        totalAmount: validation.total,
        status: OrderStatus.confirmed,
        paymentMethod: paymentMethod,
        isPaid: false,
        createdAt: DateTime.now(),
        notes: notes,
        couponCode: couponCode,
      );

      _orders.insert(0, order);
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to place order: $e';
      notifyListeners();
      rethrow;
    }
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _orderApiService.cancelOrder(orderId, reason: 'Cancelled by user');

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.cancelled,
          cancelledAt: DateTime.now(),
          cancelReason: 'Cancelled by user',
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to cancel order: $e';
      debugPrint('Error cancelling order: $e');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
