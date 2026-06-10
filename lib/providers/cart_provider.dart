import 'package:flutter/material.dart';
import '../data/models/cart.dart';
import '../data/models/product.dart';
import '../data/services/cart_api_service.dart' as cart_api;
import '../data/services/product_service.dart';
import '../data/services/secure_api_service.dart';

class CartProvider extends ChangeNotifier {
  final cart_api.CartApiService _cartApiService = cart_api.CartApiService();
  final ProductService _productService = ProductService();

  Cart _cart = Cart();
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  bool _isLoggedIn = false;
  final SecureApiService _secureApi = SecureApiService();

  // Local cart for guest users
  final List<CartItem> _localCartItems = [];

  // O(1) lookup cache for scroll performance
  Set<String> _cartProductIds = {};

  Cart get cart => _cart;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  int get itemCount => _cart.itemCount;
  bool get isEmpty => _cart.isEmpty;

  // Expose cart totals for convenience
  double get subtotal => _cart.subtotal;
  // Delivery is computed by [StoreSettingsProvider.deliveryChargeFor]; this
  // legacy getter returns 0 so any caller that hasn't migrated doesn't
  // accidentally show a stale hardcoded ₹49.
  double get deliveryCharge => 0;
  double get taxAmount => _cart.taxAmount;
  double get totalAmount => _cart.totalAmount;

  /// Set login status - call this when user logs in/out
  void setLoggedIn(bool isLoggedIn) {
    _isLoggedIn = isLoggedIn;
    if (isLoggedIn) {
      // Sync local cart to server when user logs in
      _syncLocalCartToServer();
    } else {
      // Clear server cart and use local
      _cart = Cart(items: _localCartItems);
      notifyListeners();
    }
  }

  /// Load cart from API (for logged-in users)
  Future<void> loadCart() async {
    if (!_isLoggedIn) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _cartApiService.getCart();

      // Convert API response to Cart model
      final List<CartItem> items = response.items.map((apiItem) {
        // Calculate discount percentage from price and discount
        final discountPct = apiItem.product.price > 0 && apiItem.product.discountPercentage != null
            ? apiItem.product.discountPercentage!
            : 0.0;
        final offerPrice = discountPct > 0
            ? apiItem.product.price * (1 - discountPct / 100)
            : null;

        return CartItem(
          id: apiItem.id,
          product: Product(
            id: apiItem.product.id,
            name: apiItem.product.name,
            price: apiItem.product.price,
            offerPrice: offerPrice,
            imageUrls: apiItem.product.imageUrl != null ? [apiItem.product.imageUrl!] : [],
            stock: apiItem.product.stockQuantity,
            brand: '',
            category: '',
            description: '',
            isActive: apiItem.product.isActive,
          ),
          quantity: apiItem.quantity,
        );
      }).toList();

      _cart = Cart(
        items: items,
        appliedCouponCode: _cart.appliedCouponCode,
        couponDiscount: _cart.couponDiscount,
      );

      // Enrich cart items with full product data (specs, brand, category etc.)
      _enrichCartProducts();
    } catch (e) {
      _error = 'Failed to load cart: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch full product details for cart items (specs, brand, category, rating)
  Future<void> _enrichCartProducts() async {
    final productIds = _cart.activeItems.map((item) => item.product.id).toList();
    if (productIds.isEmpty) return;

    try {
      final fullProducts = <String, Product>{};
      // Fetch all cart products in parallel
      final futures = productIds.map((id) => _productService.getProductById(id));
      final results = await Future.wait(futures);
      for (final product in results) {
        if (product != null) {
          fullProducts[product.id] = product;
        }
      }

      if (fullProducts.isNotEmpty) {
        final enrichedItems = _cart.items.map((item) {
          final fullProduct = fullProducts[item.product.id];
          if (fullProduct != null) {
            return CartItem(
              id: item.id,
              product: fullProduct,
              quantity: item.quantity,
              isSavedForLater: item.isSavedForLater,
            );
          }
          return item;
        }).toList();

        _cart = Cart(
          items: enrichedItems,
          appliedCouponCode: _cart.appliedCouponCode,
          couponDiscount: _cart.couponDiscount,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error enriching cart products: $e');
    }
  }

  /// Sync local cart to server after login
  Future<void> _syncLocalCartToServer() async {
    if (_localCartItems.isEmpty) {
      await loadCart();
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final List<cart_api.CartSyncItem> syncItems = _localCartItems.map((item) {
        return cart_api.CartSyncItem(
          productId: item.product.id,
          quantity: item.quantity,
        );
      }).toList();

      await _cartApiService.syncCart(syncItems);
      _localCartItems.clear();
      await loadCart();
    } catch (e) {
      _error = 'Failed to sync cart: $e';
    }

    _isSyncing = false;
    notifyListeners();
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (!_isLoggedIn) {
      // Guest cart kept locally; it's synced to the server on login.
      final i =
          _localCartItems.indexWhere((it) => it.product.id == product.id);
      if (i >= 0) {
        _localCartItems[i] = _localCartItems[i]
            .copyWith(quantity: _localCartItems[i].quantity + quantity);
      } else {
        _localCartItems.add(CartItem(
          id: 'local_${product.id}',
          product: product,
          quantity: quantity,
        ));
      }
      _cart = Cart(
        items: _localCartItems,
        appliedCouponCode: _cart.appliedCouponCode,
        couponDiscount: _cart.couponDiscount,
      );
      _rebuildCartLookup();
      notifyListeners();
      return;
    }
    try {
      await _cartApiService.addToCart(product.id, quantity: quantity);
      await loadCart();
    } catch (e) {
      _error = 'Failed to add to cart: $e';
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    if (_isLoggedIn) {
      try {
        await _cartApiService.removeFromCart(cartItemId);
        await loadCart();
      } catch (e) {
        _error = 'Failed to remove from cart: $e';
        notifyListeners();
      }
    } else {
      _localCartItems.removeWhere((item) => item.id == cartItemId);
      _cart = Cart(
        items: _localCartItems,
        appliedCouponCode: _cart.appliedCouponCode,
        couponDiscount: _cart.couponDiscount,
      );
      _rebuildCartLookup();
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    if (_isLoggedIn) {
      try {
        await _cartApiService.updateCartItem(cartItemId, quantity);
        await loadCart();
      } catch (e) {
        _error = 'Failed to update quantity: $e';
        notifyListeners();
      }
    } else {
      final index = _localCartItems.indexWhere((item) => item.id == cartItemId);
      if (index >= 0) {
        _localCartItems[index] = _localCartItems[index].copyWith(quantity: quantity);
        _cart = Cart(
          items: _localCartItems,
          appliedCouponCode: _cart.appliedCouponCode,
          couponDiscount: _cart.couponDiscount,
        );
        notifyListeners();
      }
    }
  }

  void saveForLater(String cartItemId) {
    List<CartItem> items = _isLoggedIn ? List<CartItem>.from(_cart.items) : _localCartItems;
    final index = items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      items[index] = items[index].copyWith(isSavedForLater: true);
      _cart = Cart(
        items: items,
        appliedCouponCode: _cart.appliedCouponCode,
        couponDiscount: _cart.couponDiscount,
      );
      notifyListeners();
    }
  }

  void moveToCart(String cartItemId) {
    List<CartItem> items = _isLoggedIn ? List<CartItem>.from(_cart.items) : _localCartItems;
    final index = items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      items[index] = items[index].copyWith(isSavedForLater: false);
      _cart = Cart(
        items: items,
        appliedCouponCode: _cart.appliedCouponCode,
        couponDiscount: _cart.couponDiscount,
      );
      notifyListeners();
    }
  }

  /// Apply a coupon code — validated SERVER-SIDE against the database.
  /// Checks coupon existence, expiry, usage limits, and min order amount.
  /// Returns error message if invalid, null if successful.
  Future<String?> applyCoupon(String code) async {
    if (code.isEmpty) return 'Please enter a coupon code';

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _secureApi.validateCoupon(
        couponCode: code,
        subtotal: _cart.subtotal,
      );

      _isLoading = false;

      if (result['valid'] == true) {
        final discount = (result['discount'] as num).toDouble();
        _cart = Cart(
          items: _cart.items,
          appliedCouponCode: code.toUpperCase(),
          couponDiscount: discount,
        );
        notifyListeners();
        return null; // Success
      } else {
        notifyListeners();
        return result['error'] as String? ?? 'Invalid coupon code';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Failed to validate coupon: $e';
    }
  }

  void removeCoupon() {
    _cart = Cart(
      items: _cart.items,
      appliedCouponCode: null,
      couponDiscount: 0,
    );
    notifyListeners();
  }

  Future<void> clearCart() async {
    if (_isLoggedIn) {
      try {
        await _cartApiService.clearCart();
        _cart = Cart();
      } catch (e) {
        _error = 'Failed to clear cart: $e';
      }
    } else {
      _localCartItems.clear();
      _cart = Cart();
    }
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _cartProductIds.contains(productId);
  }

  /// Rebuild the O(1) lookup set from cart items
  void _rebuildCartLookup() {
    _cartProductIds = _cart.activeItems.map((item) => item.product.id).toSet();
  }

  @override
  void notifyListeners() {
    _rebuildCartLookup();
    super.notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sync cart to server for persistence across devices/sessions.
  Future<void> _syncCartToServer() async {
    try {
      final items = _cart.activeItems.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
        };
      }).toList();
      await _secureApi.syncCart(items);
    } catch (e) {
      debugPrint('Cart sync failed: $e');
    }
  }

  /// Load cart from server (call on app startup after login).
  Future<void> loadCartFromServer() async {
    try {
      final result = await _secureApi.getCart();
      if (result['success'] == true) {
        // Cart loaded from server — items have fresh prices
        debugPrint('Cart loaded from server: ${result['items']?.length ?? 0} items');
      }
    } catch (e) {
      debugPrint('Failed to load cart from server: $e');
    }
  }
}
