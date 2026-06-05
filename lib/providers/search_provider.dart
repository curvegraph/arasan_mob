import 'package:flutter/material.dart';
import '../data/models/product.dart';
import '../data/models/search_suggestion.dart';
import '../data/services/api_service.dart';
import '../data/services/product_service.dart';
import 'user_activity_provider.dart';

class SearchProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final ApiService _api = ApiService();
  UserActivityProvider? _activityProvider;

  String _query = '';
  List<Product> _results = [];
  List<SearchSuggestion> _recentSearches = [];
  List<SearchSuggestion> _popularSearches = [];
  List<SearchSuggestion> _productSuggestions = [];
  bool _isSearching = false;

  /// Link to UserActivityProvider so searches are persisted for recommendations.
  void setActivityProvider(UserActivityProvider provider) {
    _activityProvider = provider;
  }

  String get query => _query;
  List<Product> get results => _results;
  List<SearchSuggestion> get recentSearches => _recentSearches;
  List<SearchSuggestion> get popularSearches => _popularSearches;
  List<SearchSuggestion> get productSuggestions => _productSuggestions;
  bool get isSearching => _isSearching;
  bool get hasResults => _results.isNotEmpty;

  List<SearchSuggestion> getSuggestions(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();

    final suggestions = <SearchSuggestion>[
      ..._recentSearches
          .where((s) => s.query.toLowerCase().contains(lowerQuery)),
    ];

    final existingQueries = suggestions.map((s) => s.query.toLowerCase()).toSet();
    if (query.length >= 2) {
      for (final s in _productSuggestions) {
        if (s.query.toLowerCase().contains(lowerQuery) &&
            !existingQueries.contains(s.query.toLowerCase())) {
          suggestions.add(s);
          existingQueries.add(s.query.toLowerCase());
        }
      }
    }

    return suggestions;
  }

  /// Live product suggestions via the backend's product search endpoint.
  Future<void> fetchProductSuggestions(String query) async {
    if (query.length < 2) {
      _productSuggestions = [];
      notifyListeners();
      return;
    }

    try {
      final data = await _api.get('/products/search', queryParams: {
        'q': query,
        'limit': '5',
      });
      final list = (data is Map && data['products'] is List)
          ? data['products'] as List
          : const [];
      _productSuggestions = list.whereType<Map>().map((row) {
        final m = Map<String, dynamic>.from(row);
        final imageUrls = m['image_urls'];
        String? imageUrl;
        if (imageUrls is List && imageUrls.isNotEmpty) {
          imageUrl = imageUrls.first as String?;
        }
        return SearchSuggestion(
          query: m['name'] as String? ?? '',
          productId: m['id'] as String?,
          type: SearchSuggestionType.product,
          imageUrl: imageUrl,
        );
      }).where((s) => s.query.isNotEmpty).toList();
      notifyListeners();
    } catch (_) {
      // Suggestions are non-critical.
    }
  }

  /// Popular searches: distinct brands + categories from the backend.
  Future<void> loadPopularSearches() async {
    try {
      final brandsData = await _api.get('/products/brands');
      final brandsList = (brandsData is Map && brandsData['brands'] is List)
          ? brandsData['brands'] as List
          : const [];
      final brands = brandsList
          .map((b) => b.toString())
          .where((b) => b.isNotEmpty)
          .toSet();

      final categoriesData = await _api.get('/categories');
      final categoriesList = (categoriesData is Map && categoriesData['categories'] is List)
          ? categoriesData['categories'] as List
          : (categoriesData is List ? categoriesData : const []);
      final categories = categoriesList
          .whereType<Map>()
          .map((c) => (c['name'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();

      _popularSearches = [
        ...brands.take(5).map((b) => SearchSuggestion(
              query: b,
              type: SearchSuggestionType.popular,
            )),
        ...categories.take(5).map((c) => SearchSuggestion(
              query: c,
              type: SearchSuggestionType.popular,
            )),
      ];
      notifyListeners();
    } catch (_) {
      // Popular searches are non-critical.
    }
  }

  Future<void> search(String query) async {
    _query = query;
    if (query.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _results = await _productService.searchProducts(query.trim());
    } catch (_) {
      _results = [];
    }

    final lowerQuery = query.toLowerCase();
    _recentSearches.removeWhere((s) => s.query.toLowerCase() == lowerQuery);
    _recentSearches.insert(
      0,
      SearchSuggestion(query: query, type: SearchSuggestionType.recent),
    );
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }

    _activityProvider?.addSearchQuery(query.trim());

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    _results = [];
    notifyListeners();
  }

  void removeRecentSearch(String query) {
    _recentSearches.removeWhere((s) => s.query == query);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches = [];
    notifyListeners();
  }
}
