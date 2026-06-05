import 'api_service.dart';
import 'product_api_service.dart';

class WishlistApiService {
  final ApiService _api = ApiService();

  /// Get user's wishlist
  Future<WishlistResponse> getWishlist({int page = 1, int limit = 20}) async {
    final response = await _api.get('/wishlist',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      requireAuth: true,
    );
    return WishlistResponse.fromJson(response);
  }

  /// Add item to wishlist
  Future<WishlistItemResponse> addToWishlist(String productId) async {
    final response = await _api.post('/wishlist',
      body: {'productId': productId},
      requireAuth: true,
    );
    return WishlistItemResponse.fromJson(response);
  }

  /// Remove item from wishlist by item ID
  Future<void> removeFromWishlist(String itemId) async {
    await _api.delete('/wishlist/$itemId', requireAuth: true);
  }

  /// Remove item from wishlist by product ID
  Future<void> removeByProductId(String productId) async {
    await _api.delete('/wishlist/product/$productId', requireAuth: true);
  }

  /// Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    final response = await _api.get('/wishlist/check/$productId', requireAuth: true);
    return response['inWishlist'] ?? false;
  }

  /// Clear entire wishlist
  Future<void> clearWishlist() async {
    await _api.delete('/wishlist', requireAuth: true);
  }

  /// Sync guest wishlist with user wishlist (after login)
  Future<SyncWishlistResponse> syncWishlist(List<String> productIds) async {
    final response = await _api.post('/wishlist/sync',
      body: {'productIds': productIds},
      requireAuth: true,
    );
    return SyncWishlistResponse.fromJson(response);
  }

  /// Move item from wishlist to cart
  Future<void> moveToCart(String itemId, {int quantity = 1}) async {
    await _api.post('/wishlist/$itemId/move-to-cart',
      body: {'quantity': quantity},
      requireAuth: true,
    );
  }
}

/// Wishlist response with pagination
class WishlistResponse {
  final List<WishlistItem> items;
  final Pagination pagination;

  WishlistResponse({required this.items, required this.pagination});

  factory WishlistResponse.fromJson(Map<String, dynamic> json) {
    return WishlistResponse(
      items: (json['items'] as List)
          .map((item) => WishlistItem.fromJson(item))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get count => items.length;
}

/// Wishlist item model
class WishlistItem {
  final String id;
  final DateTime createdAt;
  final WishlistProduct product;

  WishlistItem({
    required this.id,
    required this.createdAt,
    required this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      product: WishlistProduct.fromJson(json['product']),
    );
  }
}

/// Product info in wishlist
class WishlistProduct {
  final String id;
  final String name;
  final double price;
  final double? discountPercentage;
  final double discountedPrice;
  final String? imageUrl;
  final int stockQuantity;
  final bool isActive;
  final String? brand;
  final String? category;
  final double? averageRating;
  final bool inStock;

  WishlistProduct({
    required this.id,
    required this.name,
    required this.price,
    this.discountPercentage,
    required this.discountedPrice,
    this.imageUrl,
    required this.stockQuantity,
    required this.isActive,
    this.brand,
    this.category,
    this.averageRating,
    required this.inStock,
  });

  factory WishlistProduct.fromJson(Map<String, dynamic> json) {
    return WishlistProduct(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      imageUrl: json['image_url'] ??
          ((json['image_urls'] is List && (json['image_urls'] as List).isNotEmpty)
              ? (json['image_urls'] as List).first as String?
              : null),
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] ?? true,
      brand: json['brand'],
      category: json['category'],
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      inStock: json['in_stock'] ?? true,
    );
  }
}

/// Response for wishlist operations
class WishlistItemResponse {
  final Map<String, dynamic> wishlistItem;
  final String message;

  WishlistItemResponse({required this.wishlistItem, required this.message});

  factory WishlistItemResponse.fromJson(Map<String, dynamic> json) {
    return WishlistItemResponse(
      wishlistItem: json['wishlistItem'] ?? {},
      message: json['message'] ?? '',
    );
  }
}

/// Sync wishlist response
class SyncWishlistResponse {
  final List<dynamic> synced;
  final String message;

  SyncWishlistResponse({required this.synced, required this.message});

  factory SyncWishlistResponse.fromJson(Map<String, dynamic> json) {
    return SyncWishlistResponse(
      synced: json['synced'] ?? [],
      message: json['message'] ?? '',
    );
  }
}
