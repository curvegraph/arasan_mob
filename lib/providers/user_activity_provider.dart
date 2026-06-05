import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/product.dart';

/// Tracks user activity locally for Recently Viewed and Recommendations.
///
/// Persists:
/// - Recently viewed product IDs (max 20)
/// - Search history (max 10 queries)
///
/// Generates recommendations by matching the user's viewed/wishlisted
/// brands, categories, and price ranges against the full product catalog.
class UserActivityProvider extends ChangeNotifier {
  static const _recentlyViewedKey = 'recently_viewed_ids';
  static const _searchHistoryKey = 'search_history';
  static const int _maxRecentlyViewed = 20;
  static const int _maxSearchHistory = 10;

  List<String> _recentlyViewedIds = [];
  List<String> _searchHistory = [];
  bool _isLoaded = false;

  List<String> get recentlyViewedIds => _recentlyViewedIds;
  List<String> get searchHistory => _searchHistory;
  bool get isLoaded => _isLoaded;

  /// Call once at app startup to load persisted data.
  Future<void> init() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();

    _recentlyViewedIds = prefs.getStringList(_recentlyViewedKey) ?? [];
    _searchHistory = prefs.getStringList(_searchHistoryKey) ?? [];
    _isLoaded = true;
    notifyListeners();
  }

  // ── Recently Viewed ──────────────────────────────────────────────

  /// Add a product ID to recently viewed (moves to front if already exists).
  Future<void> addRecentlyViewed(String productId) async {
    _recentlyViewedIds.remove(productId);
    _recentlyViewedIds.insert(0, productId);
    if (_recentlyViewedIds.length > _maxRecentlyViewed) {
      _recentlyViewedIds = _recentlyViewedIds.sublist(0, _maxRecentlyViewed);
    }
    notifyListeners();
    await _persist();
  }

  /// Get recently viewed products resolved from the product catalog.
  List<Product> getRecentlyViewedProducts(List<Product> allProducts) {
    final productMap = {for (final p in allProducts) p.id: p};
    return _recentlyViewedIds
        .where((id) => productMap.containsKey(id))
        .map((id) => productMap[id]!)
        .where((p) => p.isActive)
        .toList();
  }

  void clearRecentlyViewed() async {
    _recentlyViewedIds = [];
    notifyListeners();
    await _persist();
  }

  // ── Search History ───────────────────────────────────────────────

  /// Add a search query (moves to front if already exists).
  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _searchHistory.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > _maxSearchHistory) {
      _searchHistory = _searchHistory.sublist(0, _maxSearchHistory);
    }
    notifyListeners();
    await _persist();
  }

  void removeSearchQuery(String query) async {
    _searchHistory.remove(query);
    notifyListeners();
    await _persist();
  }

  void clearSearchHistory() async {
    _searchHistory = [];
    notifyListeners();
    await _persist();
  }

  // ── Recommendations ──────────────────────────────────────────────

  /// Generate recommended products based on user's activity.
  ///
  /// Strategy (priority order):
  /// 1. Products from same brands as wishlisted items
  /// 2. Products from same categories as recently viewed
  /// 3. Products in similar price range as recently viewed
  /// 4. Products matching search history terms
  /// 5. Fall back to featured/top-rated products
  ///
  /// Excludes already-viewed products to keep it fresh.
  List<Product> getRecommendations({
    required List<Product> allProducts,
    required List<String> wishlistProductIds,
    int limit = 15,
  }) {
    if (allProducts.isEmpty) return [];

    final activeProducts = allProducts.where((p) => p.isActive).toList();
    final viewedSet = _recentlyViewedIds.toSet();
    final scored = <String, double>{};

    // Resolve wishlisted products
    final productMap = {for (final p in activeProducts) p.id: p};
    final wishlistProducts = wishlistProductIds
        .where((id) => productMap.containsKey(id))
        .map((id) => productMap[id]!)
        .toList();

    // Resolve recently viewed products
    final viewedProducts = _recentlyViewedIds
        .where((id) => productMap.containsKey(id))
        .map((id) => productMap[id]!)
        .toList();

    // Collect interest signals
    final interestedBrands = <String>{
      ...wishlistProducts.map((p) => p.brand),
      ...viewedProducts.take(5).map((p) => p.brand),
    };
    final interestedCategories = <String>{
      ...wishlistProducts.map((p) => p.category),
      ...viewedProducts.take(5).map((p) => p.category),
    };

    // Price range from recently viewed
    double minPrice = 0;
    double maxPrice = double.infinity;
    if (viewedProducts.isNotEmpty) {
      final prices = viewedProducts.take(5).map((p) => p.effectivePrice).toList();
      final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
      minPrice = avgPrice * 0.5;
      maxPrice = avgPrice * 1.5;
    }

    // Score each product
    for (final product in activeProducts) {
      if (viewedSet.contains(product.id)) continue; // Skip already viewed

      double score = 0;

      // Brand match (highest weight)
      if (interestedBrands.contains(product.brand)) score += 5;

      // Category match
      if (interestedCategories.contains(product.category)) score += 3;

      // Price range match
      if (viewedProducts.isNotEmpty &&
          product.effectivePrice >= minPrice &&
          product.effectivePrice <= maxPrice) {
        score += 2;
      }

      // Search history match
      for (final query in _searchHistory) {
        final q = query.toLowerCase();
        if (product.name.toLowerCase().contains(q) ||
            product.brand.toLowerCase().contains(q) ||
            product.category.toLowerCase().contains(q)) {
          score += 4;
          break;
        }
      }

      // Bonus for high-rated
      if (product.rating >= 4.0) score += 1;

      // Bonus for discounted
      if (product.hasDiscount) score += 0.5;

      if (score > 0) {
        scored[product.id] = score;
      }
    }

    // Sort by score descending
    final sortedIds = scored.keys.toList()
      ..sort((a, b) => scored[b]!.compareTo(scored[a]!));

    final results = sortedIds
        .take(limit)
        .map((id) => productMap[id]!)
        .toList();

    // If not enough scored results, pad with top-rated products
    if (results.length < limit) {
      final existingIds = {...results.map((p) => p.id), ...viewedSet};
      final fallback = activeProducts
          .where((p) => !existingIds.contains(p.id))
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      results.addAll(fallback.take(limit - results.length));
    }

    return results;
  }

  // ── Persistence ──────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentlyViewedKey, _recentlyViewedIds);
    await prefs.setStringList(_searchHistoryKey, _searchHistory);
  }
}
