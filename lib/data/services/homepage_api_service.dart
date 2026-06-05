import '../models/product.dart';
import 'api_service.dart';

class HomepageApiService {
  final ApiService _api = ApiService();

  /// Get complete homepage configuration (recommended - single API call)
  Future<HomepageConfig> getHomepageConfig() async {
    final response = await _api.get('/homepage/config');
    return HomepageConfig.fromJson(response);
  }

  /// Get banners only
  Future<List<Banner>> getBanners({String? type}) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;

    final response = await _api.get('/homepage/banners', queryParams: queryParams);
    return (response['banners'] as List)
        .map((json) => Banner.fromJson(json))
        .toList();
  }

  /// Get active flash deal
  Future<FlashDeal?> getFlashDeal() async {
    final response = await _api.get('/homepage/flash-deal');
    if (response['flashDeal'] == null) return null;
    return FlashDeal.fromJson(response['flashDeal']);
  }

  /// Get homepage sections with products
  Future<List<HomepageSection>> getSections({bool withProducts = true}) async {
    final response = await _api.get('/homepage/sections', queryParams: {
      'withProducts': withProducts.toString(),
    });
    return (response['sections'] as List)
        .map((json) => HomepageSection.fromJson(json))
        .toList();
  }

  /// Get brands for homepage
  Future<List<BrandInfo>> getBrands({int limit = 8}) async {
    final response = await _api.get('/homepage/brands', queryParams: {
      'limit': limit.toString(),
    });
    return (response['brands'] as List)
        .map((json) => BrandInfo.fromJson(json))
        .toList();
  }
}

/// Complete homepage configuration
class HomepageConfig {
  final List<Banner> banners;
  final List<CategoryInfo> categories;
  final List<BrandInfo> brands;
  final List<HomepageSection> sections;
  final FlashDeal? flashDeal;
  final List<Product> featuredProducts;

  HomepageConfig({
    required this.banners,
    required this.categories,
    required this.brands,
    required this.sections,
    this.flashDeal,
    required this.featuredProducts,
  });

  factory HomepageConfig.fromJson(Map<String, dynamic> json) {
    return HomepageConfig(
      banners: (json['banners'] as List)
          .map((b) => Banner.fromJson(b))
          .toList(),
      categories: (json['categories'] as List)
          .map((c) => CategoryInfo.fromJson(c))
          .toList(),
      brands: (json['brands'] as List)
          .map((b) => BrandInfo.fromJson(b))
          .toList(),
      sections: (json['sections'] as List)
          .map((s) => HomepageSection.fromJson(s))
          .toList(),
      flashDeal: json['flashDeal'] != null
          ? FlashDeal.fromJson(json['flashDeal'])
          : null,
      featuredProducts: (json['featuredProducts'] as List)
          .map((p) => Product.fromJson(p))
          .toList(),
    );
  }
}

/// Banner model
class Banner {
  final String id;
  final String? title;
  final String? subtitle;
  final String imageUrl;
  final String? linkType;
  final String? linkValue;
  final int sortOrder;
  final bool isActive;

  Banner({
    required this.id,
    this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkType,
    this.linkValue,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      imageUrl: json['image_url'] ?? '',
      linkType: json['link_type'],
      linkValue: json['link_value'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Category info for homepage
class CategoryInfo {
  final String id;
  final String name;
  final String? imageUrl;
  final String? slug;

  CategoryInfo({
    required this.id,
    required this.name,
    this.imageUrl,
    this.slug,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      slug: json['slug'],
    );
  }
}

/// Brand info for homepage
class BrandInfo {
  final String name;
  final String? imageUrl;

  BrandInfo({required this.name, this.imageUrl});

  factory BrandInfo.fromJson(Map<String, dynamic> json) {
    return BrandInfo(
      name: json['name'],
      imageUrl: json['image_url'],
    );
  }
}

/// Homepage section with products
class HomepageSection {
  final String id;
  final String title;
  final String? subtitle;
  final String type; // UI widget type: banner_carousel, product_grid, etc.
  final String filterType; // Product filter: featured, new_arrivals, category, etc.
  final String? filterValue;
  final int productLimit;
  final int displayOrder;
  final bool isActive;
  final List<Product> products;

  HomepageSection({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.filterType,
    this.filterValue,
    this.productLimit = 10,
    this.displayOrder = 0,
    this.isActive = true,
    this.products = const [],
  });

  factory HomepageSection.fromJson(Map<String, dynamic> json) {
    return HomepageSection(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      type: json['type'] ?? json['section_type'] ?? 'product_grid',
      filterType: json['filter_type'] ?? 'all', // Default to 'all' to show all products
      filterValue: json['filter_value'],
      productLimit: json['product_limit'] ?? 10,
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      products: json['products'] != null
          ? (json['products'] as List)
              .map((p) => Product.fromJson(p))
              .toList()
          : [],
    );
  }
}

/// Flash deal model
class FlashDeal {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final double? discountPercentage;
  final bool isActive;
  final List<Product> products;

  FlashDeal({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.discountPercentage,
    this.isActive = true,
    this.products = const [],
  });

  factory FlashDeal.fromJson(Map<String, dynamic> json) {
    return FlashDeal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      discountPercentage: json['discount_percentage']?.toDouble(),
      isActive: json['is_active'] ?? true,
      products: json['products'] != null
          ? (json['products'] as List)
              .map((p) => Product.fromJson(p))
              .toList()
          : [],
    );
  }

  bool get isLive {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
}
