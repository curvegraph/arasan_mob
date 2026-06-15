import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/order.dart';
import '../data/services/order_api_service.dart' show OrderApiService, OrdersListResponse, OrderSummaryItem, TrackingInfo, CartItemRequest, ShippingAddressRequest;
import '../data/services/secure_api_service.dart';

class UserOrderProvider extends ChangeNotifier {
  final OrderApiService _orderApiService = OrderApiService();
  final SecureApiService _secureApi = SecureApiService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  OrderStatus? _statusFilter;
  Timer? _pollTimer;
  String? _currentCustomerId;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<Order> get orders {
    if (_statusFilter == null) return _orders;
    return _orders.where((o) => o.status == _statusFilter).toList();
  }

  List<Order> get allOrders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderStatus? get statusFilter => _statusFilter;
  bool get hasMore => _hasMore;

  void setStatusFilter(OrderStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Polling-based realtime substitute (until Socket.IO bridge is wired).
  void initRealtimeSubscription(String customerId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadOrders(customerId);
    });
  }

  void disposeRealtimeSubscription() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    disposeRealtimeSubscription();
    super.dispose();
  }

  /// Load orders from API for the current user
  Future<void> loadOrders(String customerId) async {
    _currentCustomerId = customerId;
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await _orderApiService.getMyOrders(page: 1, limit: 20);

      _orders = response.orders.map((apiOrder) => _convertToOrder(apiOrder)).toList();
      _totalPages = response.pagination.totalPages;
      _hasMore = response.pagination.page < response.pagination.totalPages;
      _error = null;

      // Initialize polling-realtime after loading
      if (_pollTimer == null) {
        initRealtimeSubscription(customerId);
      }
    } catch (e) {
      _error = 'Failed to load orders: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _orderApiService.getMyOrders(
        page: _currentPage + 1,
        limit: 20,
      );

      final newOrders = response.orders.map((apiOrder) => _convertToOrder(apiOrder)).toList();
      _orders = [..._orders, ...newOrders];
      _currentPage++;
      _hasMore = response.pagination.page < response.pagination.totalPages;
    } catch (e) {
      _error = 'Failed to load more orders: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Convert API response to Order model
  Order _convertToOrder(OrderSummaryItem apiOrder) {
    return Order(
      id: apiOrder.id,
      orderNumber: apiOrder.orderNumber,
      customerId: _currentCustomerId ?? '',
      customerName: apiOrder.customerName,
      customerPhone: apiOrder.customerPhone,
      shippingAddress: apiOrder.shippingAddress,
      items: apiOrder.items.map((item) => OrderItem(
        productId: item.productId,
        productName: item.productName,
        imageUrl: item.imageUrl,
        quantity: item.quantity,
        price: item.unitPrice,
      )).toList(),
      subtotal: apiOrder.totalAmount,
      deliveryCharge: 0,
      taxAmount: 0,
      discountAmount: 0,
      totalAmount: apiOrder.totalAmount,
      status: _parseStatus(apiOrder.status),
      paymentMethod: apiOrder.paymentMethod,
      isPaid: apiOrder.paymentStatus.toLowerCase() == 'paid',
      createdAt: apiOrder.createdAt,
    );
  }

  OrderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      default:
        return OrderStatus.pending;
    }
  }

  /// Fetch a single order by id from the API and cache it, so a freshly-placed
  /// order can be opened directly (the detail screen reads from this cache).
  /// Returns the order, or null if it couldn't be loaded.
  Future<Order?> fetchOrderDetails(String id) async {
    try {
      final json = await _orderApiService.getOrderRaw(id);
      final items = (json['order_items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList();
      final order = Order.fromJson(json, items);
      final idx = _orders.indexWhere((o) => o.id == order.id);
      if (idx >= 0) {
        _orders = List.from(_orders)..[idx] = order;
      } else {
        _orders = [order, ..._orders];
      }
      notifyListeners();
      return order;
    } catch (e) {
      return null;
    }
  }

  /// Place a new order via API
  Future<String> placeOrder({
    required List<Map<String, dynamic>> items, // [{product_id, quantity}]
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
    String? razorpayOrderId,
    String deliveryOption = 'standard',
  }) async {
    try {
      final cartItems = items.map((item) => CartItemRequest(
        productId: item['product_id'] as String,
        quantity: item['quantity'] as int,
      )).toList();

      final shippingAddress = ShippingAddressRequest(
        line1: shippingAddressLine1,
        city: shippingCity,
        state: shippingState,
        pincode: shippingPincode,
        deliveryOption: deliveryOption,
      );

      final response = await _orderApiService.placeOrder(
        items: cartItems,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        couponCode: couponCode,
        razorpayOrderId: razorpayOrderId,
        paymentId: paymentId,
      );

      // Reload orders after placing new one
      if (_currentCustomerId != null) {
        loadOrders(_currentCustomerId!);
      }

      return response.orderNumber;
    } catch (e) {
      _error = 'Failed to place order: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel an order via API
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _orderApiService.cancelOrder(orderId, reason: reason);

      // Update local state for immediate feedback
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders = List.from(_orders);
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.cancelled,
          cancelledAt: DateTime.now(),
          cancelReason: reason,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to cancel order: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Request return for an order via backend HTTP.
  Future<void> requestReturn(String orderId, String reason) async {
    try {
      await _orderApiService.requestReturn(orderId, reason: reason);

      // Optimistic local update so the UI reflects the new status without
      // waiting for a re-fetch.
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders = List.from(_orders);
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.returned,
          returnReason: reason,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to request return: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Track order via API
  Future<TrackingInfo?> trackOrder(String orderId) async {
    try {
      return await _orderApiService.trackOrder(orderId);
    } catch (e) {
      _error = 'Failed to track order: $e';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
