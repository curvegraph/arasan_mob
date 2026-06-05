import 'package:flutter/material.dart';
import '../data/models/wishlist_item.dart';
import '../data/services/wishlist_api_service.dart' hide WishlistItem;

class WishlistProvider extends ChangeNotifier {
  final WishlistApiService _wishlistApiService = WishlistApiService();

  List<WishlistItem> _items = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _currentUserId;
  String? _error;

  // O(1) lookup cache for scroll performance
  Set<String> _wishlistIds = {};

  // Local wishlist for guest users
  final List<WishlistItem> _localItems = [];

  List<WishlistItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get itemCount => _items.length;
  String? get error => _error;

  bool isInWishlist(String productId) {
    return _wishlistIds.contains(productId);
  }

  /// Rebuild the O(1) lookup set from the items list
  void _rebuildLookup() {
    _wishlistIds = _items.map((item) => item.productId).toSet();
  }

  /// Set user ID when user logs in
  void setUserId(String? userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    if (userId != null) {
      // Sync local wishlist to server when user logs in
      _syncLocalWishlistToServer();
    } else {
      // Use local wishlist when logged out
      _items = List.from(_localItems);
      _rebuildLookup();
      notifyListeners();
    }
  }

  /// Initialize wishlist for a user - call this when user logs in
  Future<void> loadWishlist(String userId) async {
    if (_currentUserId == userId && _items.isNotEmpty) return;

    _currentUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _wishlistApiService.getWishlist();
      _items = response.items.map((apiItem) => WishlistItem(
        id: apiItem.id,
        productId: apiItem.product.id,
        notifyWhenInStock: false,
      )).toList();
      _rebuildLookup();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
      _error = 'Failed to load wishlist';
      _items = [];
      _rebuildLookup();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync local wishlist to server after login
  Future<void> _syncLocalWishlistToServer() async {
    if (_localItems.isEmpty) {
      if (_currentUserId != null) {
        await loadWishlist(_currentUserId!);
      }
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final productIds = _localItems.map((item) => item.productId).toList();
      await _wishlistApiService.syncWishlist(productIds);
      _localItems.clear();
      if (_currentUserId != null) {
        await loadWishlist(_currentUserId!);
      }
    } catch (e) {
      _error = 'Failed to sync wishlist: $e';
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Toggle wishlist item. Requires the user to be signed in — guests are
  /// expected to be intercepted by the UI's `requireAuth` helper. We no-op
  /// here so a guest tap that slips past the gate doesn't quietly mutate a
  /// "local wishlist" that never gets reconciled with the backend.
  Future<void> toggleWishlist(String productId) async {
    if (_currentUserId == null) return;

    final existingIndex = _items.indexWhere((item) => item.productId == productId);

    if (existingIndex >= 0) {
      // Remove from wishlist
      try {
        await _wishlistApiService.removeByProductId(productId);
        _items = List.from(_items)..removeAt(existingIndex);
        _rebuildLookup();
      } catch (e) {
        _error = 'Failed to remove from wishlist';
      }
    } else {
      // Add to wishlist
      try {
        final response = await _wishlistApiService.addToWishlist(productId);
        final newItem = WishlistItem(
          id: response.wishlistItem['id']?.toString() ?? 'WL${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          notifyWhenInStock: false,
        );
        _items = List.from(_items)..insert(0, newItem);
        _rebuildLookup();
      } catch (e) {
        _error = 'Failed to add to wishlist';
      }
    }
    notifyListeners();
  }

  void _toggleLocal(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items = List.from(_items)..removeAt(index);
      _localItems.removeWhere((item) => item.productId == productId);
    } else {
      final newItem = WishlistItem(
        id: 'WL${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
      );
      _items = List.from(_items)..add(newItem);
      _localItems.add(newItem);
    }
    _rebuildLookup();
    notifyListeners();
  }

  Future<void> removeFromWishlist(String productId) async {
    if (_currentUserId != null) {
      try {
        await _wishlistApiService.removeByProductId(productId);
      } catch (e) {
        debugPrint('Error removing from wishlist: $e');
      }
    }
    _items = List.from(_items)
      ..removeWhere((item) => item.productId == productId);
    _localItems.removeWhere((item) => item.productId == productId);
    _rebuildLookup();
    notifyListeners();
  }

  Future<void> toggleNotify(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final item = _items[index];
      final newValue = !item.notifyWhenInStock;

      // Note: API doesn't support notify toggle yet, so just update locally
      _items = List.from(_items);
      _items[index] = item.copyWith(notifyWhenInStock: newValue);
      notifyListeners();
    }
  }

  Future<void> clearWishlist() async {
    if (_currentUserId != null) {
      try {
        await _wishlistApiService.clearWishlist();
      } catch (e) {
        debugPrint('Error clearing wishlist: $e');
      }
    }
    _items = [];
    _localItems.clear();
    _rebuildLookup();
    notifyListeners();
  }

  /// Move item from wishlist to cart
  Future<void> moveToCart(String productId) async {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => WishlistItem(id: '', productId: ''),
    );

    if (item.id.isNotEmpty && _currentUserId != null) {
      try {
        await _wishlistApiService.moveToCart(item.id);
        _items = List.from(_items)..removeWhere((i) => i.productId == productId);
        notifyListeners();
      } catch (e) {
        _error = 'Failed to move to cart';
        notifyListeners();
      }
    }
  }

  /// Call when user logs out
  void onLogout() {
    _items = [];
    _currentUserId = null;
    _error = null;
    _rebuildLookup();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
