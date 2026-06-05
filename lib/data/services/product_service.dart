import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _api = ApiService();

  List<Product> _parseList(dynamic data) {
    final list = (data is Map && data['products'] is List)
        ? data['products'] as List
        : (data is List ? data : const []);
    return list
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Product>> getAllProducts() async {
    final data = await _api.get('/products', queryParams: {'limit': '1000'});
    return _parseList(data);
  }

  Future<List<Product>> getProductsByCategoryLimited(String category, {int limit = 10}) async {
    final data = await _api.get('/products/category/$category',
        queryParams: {'limit': '$limit'});
    return _parseList(data);
  }

  Future<List<Product>> getProductsByBrandLimited(String brand, {int limit = 10}) async {
    final data = await _api.get('/products/brand/$brand',
        queryParams: {'limit': '$limit'});
    return _parseList(data);
  }

  Future<List<Product>> getFeaturedProducts() async {
    final data = await _api.get('/products/featured');
    return _parseList(data);
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final data = await _api.get('/products/category/$category');
    return _parseList(data);
  }

  Future<List<Product>> getProductsByBrand(String brand) async {
    final data = await _api.get('/products/brand/$brand');
    return _parseList(data);
  }

  /// Fetch a list of products by their IDs.
  /// Backend doesn't have a bulk endpoint, so we fetch them in parallel.
  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final futures = ids.map((id) => getProductById(id));
    final results = await Future.wait(futures);
    return results.whereType<Product>().toList();
  }

  Future<Product?> getProductById(String id) async {
    try {
      final data = await _api.get('/products/$id');
      final m = (data is Map && data['product'] is Map)
          ? Map<String, dynamic>.from(data['product'] as Map)
          : Map<String, dynamic>.from(data as Map);
      return Product.fromJson(m);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final data = await _api.get('/products/search', queryParams: {'q': query});
    return _parseList(data);
  }

  Future<List<String>> getUniqueBrands() async {
    final data = await _api.get('/products/brands');
    final list = (data is Map && data['brands'] is List)
        ? data['brands'] as List
        : (data is List ? data : const []);
    final brands = list.map((e) => e.toString()).toSet().toList()..sort();
    return brands;
  }

  Future<List<Product>> getProductsPaginated({
    int page = 0,
    int pageSize = 15,
    String sortColumn = 'display_order',
    bool ascending = true,
  }) async {
    final data = await _api.get('/products', queryParams: {
      'page': '${page + 1}',
      'limit': '$pageSize',
      'sort': sortColumn,
      'order': ascending ? 'asc' : 'desc',
    });
    return _parseList(data);
  }

  Future<List<String>> getUniqueCategories() async {
    final data = await _api.get('/products/categories');
    final list = (data is Map && data['categories'] is List)
        ? data['categories'] as List
        : (data is List ? data : const []);
    final categories = list.map((e) => e.toString()).toSet().toList()..sort();
    return categories;
  }

  Future<List<Product>> getFilteredProductsPaginated({
    String? category,
    String? brand,
    Set<String>? brands,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? minDiscount,
    bool inStockOnly = false,
    int page = 0,
    int pageSize = 15,
    String sortColumn = 'display_order',
    bool ascending = true,
  }) async {
    final params = <String, String>{
      'page': '${page + 1}',
      'limit': '$pageSize',
      'sort': sortColumn,
      'order': ascending ? 'asc' : 'desc',
    };
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    if (minPrice != null && minPrice > 0) params['minPrice'] = '$minPrice';
    if (maxPrice != null && maxPrice < 200000) params['maxPrice'] = '$maxPrice';
    if (minRating != null && minRating > 0) params['minRating'] = '$minRating';
    if (minDiscount != null && minDiscount > 0) params['minDiscount'] = '$minDiscount';
    if (inStockOnly) params['inStock'] = 'true';

    // Multiple brands -> client-side merge (backend takes single brand)
    if (brands != null && brands.isNotEmpty) {
      final results = <Product>[];
      final seen = <String>{};
      for (final b in brands) {
        final p = Map<String, String>.from(params);
        p['brand'] = b;
        final data = await _api.get('/products', queryParams: p);
        for (final product in _parseList(data)) {
          if (seen.add(product.id)) results.add(product);
        }
      }
      return results;
    }

    final data = await _api.get('/products', queryParams: params);
    return _parseList(data);
  }

  Future<List<String>> getBrandsForCategory(String category) async {
    final data = await _api.get('/products/brands',
        queryParams: {'category': category});
    final list = (data is Map && data['brands'] is List)
        ? data['brands'] as List
        : (data is List ? data : const []);
    final brands = list.map((e) => e.toString()).toSet().toList()..sort();
    return brands;
  }

  /// Get on-sale products (offer_price < price). Filtered client-side
  /// because the backend doesn't expose a discount predicate.
  Future<List<Product>> getOnSaleProductsPaginated({
    String? category,
    String? brand,
    int page = 0,
    int pageSize = 12,
  }) async {
    final params = <String, String>{
      'page': '${page + 1}',
      'limit': '${pageSize * 2}', // overfetch to compensate for client-side filter
      'sort': 'created_at',
      'order': 'desc',
      'minDiscount': '1',
    };
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    final data = await _api.get('/products', queryParams: params);
    final products = _parseList(data)
        .where((p) => p.offerPrice != null && p.offerPrice! < p.price)
        .take(pageSize)
        .toList();
    return products;
  }

  Future<List<Product>> getFeaturedProductsPaginated({
    String? category,
    String? brand,
    int page = 0,
    int pageSize = 12,
  }) async {
    final params = <String, String>{
      'page': '${page + 1}',
      'limit': '$pageSize',
      'featured': 'true',
      'sort': 'display_order',
      'order': 'asc',
    };
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    final data = await _api.get('/products', queryParams: params);
    return _parseList(data);
  }

  Future<List<Product>> getNewArrivalsPaginated({
    String? category,
    String? brand,
    int daysFilter = 30,
    int page = 0,
    int pageSize = 12,
  }) async {
    final params = <String, String>{
      'page': '${page + 1}',
      'limit': '$pageSize',
      'sort': 'created_at',
      'order': 'desc',
    };
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    final data = await _api.get('/products', queryParams: params);
    var products = _parseList(data);
    if (daysFilter > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: daysFilter));
      products = products.where((p) => p.createdAt.isAfter(cutoff)).toList();
    }
    return products;
  }

  Future<List<String>> getCategoriesForBrand(String brand) async {
    final data = await _api.get('/products/categories',
        queryParams: {'brand': brand});
    final list = (data is Map && data['categories'] is List)
        ? data['categories'] as List
        : (data is List ? data : const []);
    final categories = list.map((e) => e.toString()).toSet().toList()..sort();
    return categories;
  }
}
