import '../models/product.dart';
import 'api_service.dart';

class ProductApiService {
  final ApiService _api = ApiService();

  /// Get products with filtering and pagination
  Future<ProductsResponse> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? minDiscount,
    bool? inStock,
    bool? featured,
    String sort = 'created_at',
    String order = 'desc',
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      'order': order,
    };

    if (category != null) queryParams['category'] = category;
    if (brand != null) queryParams['brand'] = brand;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (minDiscount != null) queryParams['minDiscount'] = minDiscount.toString();
    if (inStock != null) queryParams['inStock'] = inStock.toString();
    if (featured != null) queryParams['featured'] = featured.toString();
    if (search != null) queryParams['search'] = search;

    final response = await _api.get('/products', queryParams: queryParams);
    return ProductsResponse.fromJson(response);
  }

  /// Get product by ID
  Future<Product> getProductById(String id) async {
    final response = await _api.get('/products/$id');
    return Product.fromJson(response['product']);
  }

  /// Get featured products
  Future<ProductsResponse> getFeaturedProducts({
    int page = 1,
    int limit = 10,
    String? category,
    String? brand,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (brand != null) queryParams['brand'] = brand;

    final response = await _api.get('/products/featured', queryParams: queryParams);
    return ProductsResponse.fromJson(response);
  }

  /// Search products
  Future<ProductsResponse> searchProducts(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/products/search', queryParams: {
      'q': query,
      'page': page.toString(),
      'limit': limit.toString(),
    });
    return ProductsResponse.fromJson(response);
  }

  /// Get products by category
  Future<ProductsResponse> getProductsByCategory(
    String category, {
    int page = 1,
    int limit = 20,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final response = await _api.get('/products/category/$category', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      'order': order,
    });
    return ProductsResponse.fromJson(response);
  }

  /// Get products by brand
  Future<ProductsResponse> getProductsByBrand(
    String brand, {
    int page = 1,
    int limit = 20,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final response = await _api.get('/products/brand/$brand', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      'order': order,
    });
    return ProductsResponse.fromJson(response);
  }

  /// Get unique brands
  Future<List<String>> getBrands({String? category}) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;

    final response = await _api.get('/products/brands', queryParams: queryParams);
    return List<String>.from(response['brands']);
  }

  /// Get unique categories
  Future<List<String>> getCategories({String? brand}) async {
    final queryParams = <String, String>{};
    if (brand != null) queryParams['brand'] = brand;

    final response = await _api.get('/products/categories', queryParams: queryParams);
    return List<String>.from(response['categories']);
  }

  /// Get related products
  Future<List<Product>> getRelatedProducts(String productId, {int limit = 8}) async {
    final response = await _api.get('/products/$productId/related', queryParams: {
      'limit': limit.toString(),
    });
    return (response['products'] as List)
        .map((json) => Product.fromJson(json))
        .toList();
  }

  /// Get price range for filters
  Future<PriceRange> getPriceRange({String? category, String? brand}) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (brand != null) queryParams['brand'] = brand;

    final response = await _api.get('/products/price-range', queryParams: queryParams);
    return PriceRange(
      minPrice: (response['minPrice'] as num).toDouble(),
      maxPrice: (response['maxPrice'] as num).toDouble(),
    );
  }
}

/// Response model for paginated products
class ProductsResponse {
  final List<Product> products;
  final Pagination pagination;

  ProductsResponse({required this.products, required this.pagination});

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      products: (json['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

/// Pagination model
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

/// Price range model
class PriceRange {
  final double minPrice;
  final double maxPrice;

  PriceRange({required this.minPrice, required this.maxPrice});
}
