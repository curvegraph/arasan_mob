import 'api_service.dart';

class CartApiService {
  final ApiService _api = ApiService();

  /// Get user's cart
  Future<CartResponse> getCart() async {
    final response = await _api.get('/cart', requireAuth: true);
    return CartResponse.fromJson(response);
  }

  /// Add item to cart
  Future<CartItemResponse> addToCart(String productId, {int quantity = 1}) async {
    final response = await _api.post('/cart',
      body: {
        'productId': productId,
        'quantity': quantity,
      },
      requireAuth: true,
    );
    return CartItemResponse.fromJson(response);
  }

  /// Update cart item quantity
  Future<CartItemResponse> updateCartItem(String itemId, int quantity) async {
    final response = await _api.patch('/cart/$itemId',
      body: {'quantity': quantity},
      requireAuth: true,
    );
    return CartItemResponse.fromJson(response);
  }

  /// Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    await _api.delete('/cart/$itemId', requireAuth: true);
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    await _api.delete('/cart', requireAuth: true);
  }

  /// Sync guest cart with user cart (after login)
  Future<SyncResponse> syncCart(List<CartSyncItem> items) async {
    final response = await _api.post('/cart/sync',
      body: {
        'items': items.map((i) => i.toJson()).toList(),
      },
      requireAuth: true,
    );
    return SyncResponse.fromJson(response);
  }
}

/// Cart response with items and totals
class CartResponse {
  final List<CartItem> items;
  final int itemCount;
  final double subtotal;

  CartResponse({
    required this.items,
    required this.itemCount,
    required this.subtotal,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      itemCount: json['itemCount'] ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// Cart item model
class CartItem {
  final String id;
  final int quantity;
  final CartProduct product;
  final double lineTotal;

  CartItem({
    required this.id,
    required this.quantity,
    required this.product,
    required this.lineTotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      quantity: json['quantity'],
      product: CartProduct.fromJson(json['product']),
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }
}

/// Product info in cart
class CartProduct {
  final String id;
  final String name;
  final double price;
  final double? discountPercentage;
  final double discountedPrice;
  final String? imageUrl;
  final int stockQuantity;
  final bool isActive;

  CartProduct({
    required this.id,
    required this.name,
    required this.price,
    this.discountPercentage,
    required this.discountedPrice,
    this.imageUrl,
    required this.stockQuantity,
    required this.isActive,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      imageUrl: json['image_url'],
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  bool get inStock => stockQuantity > 0;
}

/// Response for cart operations
class CartItemResponse {
  final Map<String, dynamic> cartItem;
  final String message;

  CartItemResponse({required this.cartItem, required this.message});

  factory CartItemResponse.fromJson(Map<String, dynamic> json) {
    return CartItemResponse(
      cartItem: json['cartItem'] ?? {},
      message: json['message'] ?? '',
    );
  }
}

/// Item for syncing cart
class CartSyncItem {
  final String productId;
  final int quantity;

  CartSyncItem({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

/// Sync response
class SyncResponse {
  final List<dynamic> synced;
  final String message;

  SyncResponse({required this.synced, required this.message});

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      synced: json['synced'] ?? [],
      message: json['message'] ?? '',
    );
  }
}
