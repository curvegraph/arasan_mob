import 'api_service.dart';

class CategoryApiService {
  final ApiService _api = ApiService();

  /// Get all categories (hierarchical by default)
  Future<List<Category>> getCategories({bool flat = false, bool activeOnly = true}) async {
    final response = await _api.get('/categories', queryParams: {
      'flat': flat.toString(),
      'activeOnly': activeOnly.toString(),
    });
    return (response['categories'] as List)
        .map((json) => Category.fromJson(json))
        .toList();
  }

  /// Get root categories only
  Future<List<Category>> getRootCategories({int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _api.get('/categories/root', queryParams: queryParams);
    return (response['categories'] as List)
        .map((json) => Category.fromJson(json))
        .toList();
  }

  /// Get categories with product count
  Future<List<CategoryWithCount>> getCategoriesWithCount() async {
    final response = await _api.get('/categories/with-count');
    return (response['categories'] as List)
        .map((json) => CategoryWithCount.fromJson(json))
        .toList();
  }

  /// Get category by ID
  Future<CategoryDetails> getCategoryById(String id) async {
    final response = await _api.get('/categories/$id');
    return CategoryDetails.fromJson(response);
  }

  /// Get category by slug
  Future<CategoryDetails> getCategoryBySlug(String slug) async {
    final response = await _api.get('/categories/slug/$slug');
    return CategoryDetails.fromJson(response);
  }

  /// Get subcategories
  Future<List<Category>> getSubcategories(String parentId) async {
    final response = await _api.get('/categories/$parentId/subcategories');
    return (response['subcategories'] as List)
        .map((json) => Category.fromJson(json))
        .toList();
  }
}

/// Category model
class Category {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      imageUrl: json['image_url'],
      parentId: json['parent_id'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => Category.fromJson(c))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'image_url': imageUrl,
    'parent_id': parentId,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}

/// Category with product count
class CategoryWithCount extends Category {
  final int productCount;

  CategoryWithCount({
    required super.id,
    required super.name,
    super.slug,
    super.description,
    super.imageUrl,
    super.parentId,
    super.sortOrder,
    super.isActive,
    super.children,
    required this.productCount,
  });

  factory CategoryWithCount.fromJson(Map<String, dynamic> json) {
    return CategoryWithCount(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      imageUrl: json['image_url'],
      parentId: json['parent_id'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      productCount: json['productCount'] ?? 0,
    );
  }
}

/// Category details with subcategories
class CategoryDetails {
  final Category category;
  final List<Category> subcategories;

  CategoryDetails({required this.category, required this.subcategories});

  factory CategoryDetails.fromJson(Map<String, dynamic> json) {
    return CategoryDetails(
      category: Category.fromJson(json['category']),
      subcategories: (json['subcategories'] as List)
          .map((c) => Category.fromJson(c))
          .toList(),
    );
  }
}
