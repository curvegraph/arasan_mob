import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/product.dart';
import '../data/services/product_api_service.dart';
import '../data/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductApiService _productApiService = ProductApiService();
  final ProductService _productService = ProductService();
  Timer? _pollTimer;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';

  // Home page "All Products" state (separate from listing page)
  List<Product> _homeProducts = [];
  int _homePage = 1;
  bool _homeHasMore = true;
  bool _homeIsLoadingMore = false;
  bool _homeIsLoading = false;

  // Listing page pagination state
  List<Product> _paginatedProducts = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isLoadingPaginated = false;
  final int _pageSize = 15;
  String _sortColumn = 'created_at';
  bool _sortAscending = false;

  // Filter state for product listing
  String? _filterCategory;
  String? _filterBrand;
  Set<String> _selectedBrands = {};
  double _minPrice = 0;
  double _maxPrice = 200000;
  double _minRating = 0;
  double _minDiscount = 0;
  bool _inStockOnly = false;

  // Dynamic filter options
  List<String> _availableBrands = [];
  List<String> _availableCategories = [];

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedBrand => _selectedBrand;

  // Home page getters
  List<Product> get homeProducts => _homeProducts;
  bool get homeHasMore => _homeHasMore;
  bool get homeIsLoadingMore => _homeIsLoadingMore;
  bool get homeIsLoading => _homeIsLoading;

  // Listing page pagination getters
  List<Product> get paginatedProducts => _paginatedProducts;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  // Filter getters
  String? get filterCategory => _filterCategory;
  String? get filterBrand => _filterBrand;
  Set<String> get selectedFilterBrands => _selectedBrands;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get minRating => _minRating;
  double get minDiscount => _minDiscount;
  bool get inStockOnly => _inStockOnly;
  List<String> get availableBrands => _availableBrands;
  List<String> get availableCategories => _availableCategories;

  bool get hasActiveFilters =>
      _selectedBrands.isNotEmpty ||
      _minPrice > 0 ||
      _maxPrice < 200000 ||
      _minRating > 0 ||
      _minDiscount > 0 ||
      _inStockOnly;

  List<String> get categories =>
      ['All', ...{..._products.map((p) => p.category)}];
  List<String> get brands => ['All', ...{..._products.map((p) => p.brand)}];

  List<Product> get _filteredProducts {
    var filtered = _products.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q))
          .toList();
    }
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    if (_selectedBrand != 'All') {
      filtered = filtered.where((p) => p.brand == _selectedBrand).toList();
    }
    return filtered;
  }

  List<Product> get featuredProducts =>
      _products.where((p) => p.isFeatured).toList();

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock || p.isOutOfStock).toList();

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getAllProducts();
      _error = null;
    } catch (e) {
      _error = 'Failed to load products: $e';
    }

    _isLoading = false;
    notifyListeners();
    _ensureRealtime();
  }

  /// Polling-based realtime substitute (until Socket.IO bridge is wired).
  void _ensureRealtime() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshLists());
  }

  Future<void> _refreshLists() async {
    try {
      _products = await _productService.getAllProducts();
      // Re-fetch the visible listing pages so deleted/edited items reflect.
      if (_homeProducts.isNotEmpty) {
        await loadHomeProducts();
      }
      if (_paginatedProducts.isNotEmpty) {
        await loadInitialProducts();
      }
      notifyListeners();
    } catch (_) {
      // Best-effort refresh.
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  /// Load first page of home products (no filters, separate from listing page)
  Future<void> loadHomeProducts() async {
    if (_homeIsLoading) return;
    _homeIsLoading = true;
    notifyListeners();

    try {
      final response = await _productApiService.getProducts(
        page: 1,
        limit: _pageSize,
        sort: 'created_at',
        order: 'desc',
      );

      _homeProducts = response.products;
      _homeHasMore = response.pagination.hasNextPage;
      _homePage = 1;
    } catch (_) {
      // Silently fail
    }

    _homeIsLoading = false;
    notifyListeners();
    _ensureRealtime();
  }

  /// Load next page of home products
  Future<void> loadMoreHomeProducts() async {
    if (_homeIsLoadingMore || !_homeHasMore) return;

    _homeIsLoadingMore = true;
    notifyListeners();

    try {
      final response = await _productApiService.getProducts(
        page: _homePage + 1,
        limit: _pageSize,
        sort: 'created_at',
        order: 'desc',
      );

      _homeProducts.addAll(response.products);
      _homeHasMore = response.pagination.hasNextPage;
      _homePage++;
    } catch (_) {
      // Silently fail
    }

    _homeIsLoadingMore = false;
    notifyListeners();
  }

  /// Load first page of listing products (resets pagination)
  Future<void> loadInitialProducts() async {
    if (_isLoadingPaginated) return;
    _isLoadingPaginated = true;

    _currentPage = 1;
    _hasMore = true;
    _paginatedProducts = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Brand filter from URL query param (single brand) — use Supabase
      // directly so case-insensitive matching (`ilike`) works. The Node
      // API path uses exact equality which breaks when the admin brand
      // name and the products.brand text differ in case (e.g.
      // "iqoo" vs "iQOO").
      if (_selectedBrands.isEmpty &&
          _filterBrand != null &&
          _filterBrand!.isNotEmpty) {
        final products =
            await _productService.getProductsByBrand(_filterBrand!);
        _paginatedProducts = products;
        _hasMore = false; // single-shot fetch, no server pagination
        _currentPage = 1;
      } else {
        // Build brand parameter (API accepts single brand or comma-separated list)
        String? brandParam;
        if (_selectedBrands.isNotEmpty) {
          brandParam = _selectedBrands.join(',');
        }

        final response = await _productApiService.getProducts(
          page: 1,
          limit: _pageSize,
          category: _filterCategory,
          brand: brandParam,
          minPrice: _minPrice > 0 ? _minPrice : null,
          maxPrice: _maxPrice < 200000 ? _maxPrice : null,
          minRating: _minRating > 0 ? _minRating : null,
          minDiscount: _minDiscount > 0 ? _minDiscount : null,
          inStock: _inStockOnly ? true : null,
          sort: _sortColumn,
          order: _sortAscending ? 'asc' : 'desc',
        );

        _paginatedProducts = response.products;
        _hasMore = response.pagination.hasNextPage;
        _currentPage = 1;
      }
    } catch (e) {
      _error = 'Failed to load products: $e';
    }

    _isLoading = false;
    _isLoadingPaginated = false;
    notifyListeners();
    _ensureRealtime();
  }

  /// Load next page of products (appends to list)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Build brand parameter
      String? brandParam;
      if (_selectedBrands.isNotEmpty) {
        brandParam = _selectedBrands.join(',');
      } else if (_filterBrand != null) {
        brandParam = _filterBrand;
      }

      final response = await _productApiService.getProducts(
        page: _currentPage + 1,
        limit: _pageSize,
        category: _filterCategory,
        brand: brandParam,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 200000 ? _maxPrice : null,
        minRating: _minRating > 0 ? _minRating : null,
        minDiscount: _minDiscount > 0 ? _minDiscount : null,
        inStock: _inStockOnly ? true : null,
        sort: _sortColumn,
        order: _sortAscending ? 'asc' : 'desc',
      );

      _paginatedProducts.addAll(response.products);
      _hasMore = response.pagination.hasNextPage;
      _currentPage++;
      _error = null;
    } catch (e) {
      _error = 'Failed to load more products: $e';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Change sort order and reload from first page
  void changeSortOrder(String column, bool ascending) {
    _sortColumn = column;
    _sortAscending = ascending;
    loadInitialProducts();
  }

  /// Set filter category (from URL query param) and load available brands
  /// Optimized: Sets loading state immediately for instant UI feedback
  Future<void> setFilterCategory(String? category) async {
    // Set loading state IMMEDIATELY - this ensures skeleton loaders show right away
    _isLoading = true;
    _isLoadingPaginated = true;
    _error = null;
    _paginatedProducts = []; // Clear old products to show placeholders
    notifyListeners();

    // Reset filters
    _filterCategory = category;
    _filterBrand = null;
    _selectedBrands = {};
    _resetFilterValues();
    _availableCategories = [];

    try {
      // Fetch brands and products in parallel
      final brandsFuture = (category != null && category.isNotEmpty)
          ? _productService.getBrandsForCategory(category)
          : _productService.getUniqueBrands();

      final results = await Future.wait([brandsFuture, _loadProductsInternal()]);
      _availableBrands = results[0] as List<String>;
    } catch (e) {
      _error = 'Failed to load products: $e';
      _isLoading = false;
      _isLoadingPaginated = false;
    }
    notifyListeners();
  }

  /// Set filter brand (from URL query param) and load available categories
  /// Optimized: Sets loading state immediately for instant UI feedback
  Future<void> setFilterBrand(String? brand) async {
    // Set loading state IMMEDIATELY - this ensures skeleton loaders show right away
    _isLoading = true;
    _isLoadingPaginated = true;
    _error = null;
    _paginatedProducts = []; // Clear old products to show placeholders
    notifyListeners();

    // Reset filters
    _filterBrand = brand;
    _filterCategory = null;
    _selectedBrands = {};
    _resetFilterValues();
    _availableBrands = [];

    try {
      // Fetch categories and products in parallel
      final categoriesFuture = (brand != null && brand.isNotEmpty)
          ? _productService.getCategoriesForBrand(brand)
          : _productService.getUniqueCategories();

      final results = await Future.wait([categoriesFuture, _loadProductsInternal()]);
      _availableCategories = results[0] as List<String>;
    } catch (e) {
      _error = 'Failed to load products: $e';
      _isLoading = false;
      _isLoadingPaginated = false;
    }
    notifyListeners();
  }

  /// Initialize listing with no category/brand pre-filter (show all)
  /// Optimized: Sets loading state immediately for instant UI feedback
  Future<void> initListing() async {
    // Set loading state IMMEDIATELY - this ensures skeleton loaders show right away
    _isLoading = true;
    _isLoadingPaginated = true;
    _error = null;
    _paginatedProducts = []; // Clear old products to show placeholders
    notifyListeners();

    // Reset filters
    _filterCategory = null;
    _filterBrand = null;
    _selectedBrands = {};
    _resetFilterValues();

    try {
      // Fetch brands, categories, and products all in parallel
      final results = await Future.wait([
        _productService.getUniqueBrands(),
        _productService.getUniqueCategories(),
        _loadProductsInternal(),
      ]);
      _availableBrands = results[0] as List<String>;
      _availableCategories = results[1] as List<String>;
    } catch (e) {
      _error = 'Failed to load products: $e';
      _isLoading = false;
      _isLoadingPaginated = false;
    }
    notifyListeners();
  }

  /// Internal helper: loads first page of filtered products and returns the result
  Future<List<Product>> _loadProductsInternal() async {
    _currentPage = 0;
    _hasMore = true;
    _paginatedProducts = [];

    try {
      final results = await _productService.getFilteredProductsPaginated(
        category: _filterCategory,
        brand: _filterBrand,
        brands: _selectedBrands.isNotEmpty ? _selectedBrands : null,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 200000 ? _maxPrice : null,
        minRating: _minRating > 0 ? _minRating : null,
        minDiscount: _minDiscount > 0 ? _minDiscount : null,
        inStockOnly: _inStockOnly,
        page: 0,
        pageSize: _pageSize,
        sortColumn: _sortColumn,
        ascending: _sortAscending,
      );

      if (results.length > _pageSize) {
        _paginatedProducts = results.sublist(0, _pageSize);
        _hasMore = true;
      } else {
        _paginatedProducts = results;
        _hasMore = false;
      }
      _currentPage = 1;
    } catch (e) {
      _error = 'Failed to load products: $e';
    }

    _isLoading = false;
    _isLoadingPaginated = false;
    return _paginatedProducts;
  }

  /// Toggle a brand in the multi-select brand filter
  void toggleBrandFilter(String brand) {
    if (_selectedBrands.contains(brand)) {
      _selectedBrands.remove(brand);
    } else {
      _selectedBrands.add(brand);
    }
    loadInitialProducts();
  }

  /// Set price range filter
  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    loadInitialProducts();
  }

  /// Set minimum rating filter
  void setMinRating(double rating) {
    _minRating = _minRating == rating ? 0 : rating;
    loadInitialProducts();
  }

  /// Set minimum discount filter
  void setMinDiscount(double discount) {
    _minDiscount = _minDiscount == discount ? 0 : discount;
    loadInitialProducts();
  }

  /// Toggle in-stock-only filter
  void toggleInStockOnly() {
    _inStockOnly = !_inStockOnly;
    loadInitialProducts();
  }

  /// Apply all filters at once (used by mobile bottom sheet)
  void applyFilters({
    Set<String>? brands,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? minDiscount,
    bool? inStockOnly,
  }) {
    _selectedBrands = brands ?? {};
    _minPrice = minPrice ?? 0;
    _maxPrice = maxPrice ?? 200000;
    _minRating = minRating ?? 0;
    _minDiscount = minDiscount ?? 0;
    _inStockOnly = inStockOnly ?? false;
    loadInitialProducts();
  }

  /// Clear all sidebar filters (keeps category/brand from URL)
  void clearAllFilters() {
    _selectedBrands = {};
    _resetFilterValues();
    loadInitialProducts();
  }

  void _resetFilterValues() {
    _minPrice = 0;
    _maxPrice = 200000;
    _minRating = 0;
    _minDiscount = 0;
    _inStockOnly = false;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setBrand(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  /// Get product by ID from local cache (sync version for UI)
  Product? getProductById(String id) {
    // Search across all product lists
    for (final list in [_products, _homeProducts, _paginatedProducts]) {
      try {
        return list.firstWhere((p) => p.id == id);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Get product by ID from Supabase (async version)
  Future<Product?> fetchProductById(String id) async {
    // Check if we have a full product (with description/specs AND variants)
    // cached. Variants only come from the detail endpoint, so re-fetch when
    // they're missing even if a lightweight listing copy had a description.
    final cached = getProductById(id);
    if (cached != null &&
        cached.description.isNotEmpty &&
        cached.variants.isNotEmpty) {
      return cached;
    }

    // Always fetch full product for detail page (listing cache is lightweight)
    try {
      final product = await _productService.getProductById(id);
      if (product != null) {
        // Replace lightweight cached version with full version
        _products.removeWhere((p) => p.id == id);
        _homeProducts.removeWhere((p) => p.id == id);
        _paginatedProducts.removeWhere((p) => p.id == id);
        _products.add(product);
        notifyListeners();
      }
      return product;
    } catch (e) {
      return null;
    }
  }

  /// Search products
  Future<List<Product>> searchProductsApi(String query, {int page = 1, int limit = 20}) async {
    final response = await _productApiService.searchProducts(query, page: page, limit: limit);
    return response.products;
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProductsApi({int limit = 10}) async {
    final response = await _productApiService.getFeaturedProducts(limit: limit);
    return response.products;
  }

  /// Get related products (same category or brand)
  Future<List<Product>> getRelatedProducts(String productId, {int limit = 8}) async {
    try {
      return await _productApiService.getRelatedProducts(productId, limit: limit);
    } catch (_) {
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
