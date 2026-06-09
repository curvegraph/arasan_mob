import 'product.dart';

/// Homepage configuration loaded from Supabase
class HomepageConfig {
  final List<HomepageSection> sections;
  final List<BannerData> banners;
  final List<CategoryData> categories;
  final List<BrandData> brands;
  final FlashDealData? flashDeal;

  HomepageConfig({
    required this.sections,
    required this.banners,
    required this.categories,
    required this.brands,
    this.flashDeal,
  });

  factory HomepageConfig.fromJson(Map<String, dynamic> json) {
    return HomepageConfig(
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => HomepageSection.fromJson(e))
              .toList() ??
          [],
      banners: (json['banners'] as List<dynamic>?)
              ?.map((e) => BannerData.fromJson(e))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => CategoryData.fromJson(e))
              .toList() ??
          [],
      brands: (json['brands'] as List<dynamic>?)
              ?.map((e) => BrandData.fromJson(e))
              .toList() ??
          [],
      flashDeal: json['flash_deal'] != null
          ? FlashDealData.fromJson(json['flash_deal'])
          : null,
    );
  }

  factory HomepageConfig.empty() {
    return HomepageConfig(
      sections: [],
      banners: [],
      categories: [],
      brands: [],
    );
  }
}

/// Section configuration
class HomepageSection {
  final String id;
  final String key;
  final String? title;
  final String? subtitle;
  final String type;
  final Map<String, dynamic> config;
  final String? filterType;
  final String? filterValue;
  final List<String> productIds;
  final int displayOrder;

  /// Products resolved server-side by the backend for this section, honoring
  /// every admin convention (curated ids, `product_source`, deal filters,
  /// `today_offers` items, manual-empty → empty). The mobile UI renders these
  /// directly so it stays a faithful mirror of the admin config — the same
  /// data the web storefront is driven by. Empty when the section carries no
  /// products (or isn't a product-bearing section).
  final List<Product> products;

  HomepageSection({
    required this.id,
    required this.key,
    this.title,
    this.subtitle,
    required this.type,
    required this.config,
    this.filterType,
    this.filterValue,
    required this.productIds,
    this.displayOrder = 0,
    this.products = const [],
  });

  factory HomepageSection.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ?? '';
    final type = json['type'] ?? json['section_type'] ?? 'product_carousel';

    // Generate key from: section_key > key > type-based key > title
    String key = json['section_key'] ?? json['key'] ?? '';
    if (key.isEmpty) {
      // Generate key from type
      switch (type) {
        case 'banner_carousel':
          key = 'banners';
          break;
        case 'category_grid':
          key = 'categories';
          break;
        case 'countdown_deals':
          key = 'flash_deals';
          break;
        case 'brand_grid':
          key = 'brands';
          break;
        case 'product_grid':
          final source = (json['config'] is Map) ? json['config']['product_source'] : null;
          key = source == 'featured' ? 'featured_products' :
                source == 'new' ? 'new_arrivals' :
                source == 'best_selling' ? 'best_sellers' : 'all_products';
          break;
        default:
          key = title.toLowerCase().replaceAll(' ', '_');
      }
    }

    return HomepageSection(
      id: json['id']?.toString() ?? '',
      key: key,
      title: title.isNotEmpty ? title : null,
      subtitle: json['subtitle'],
      type: type,
      config: json['config'] is Map ? Map<String, dynamic>.from(json['config']) : {},
      filterType: json['filter_type'],
      filterValue: json['filter_value'],
      productIds: (json['product_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      displayOrder: json['display_order'] ?? 0,
      products: _parseProducts(json['products']),
    );
  }

  /// Parse the backend-resolved product rows defensively — one malformed row
  /// must not blow up the whole section (which would blank the homepage).
  static List<Product> _parseProducts(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Product>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(Product.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {
          // Skip rows the model can't parse rather than failing the section.
        }
      }
    }
    return out;
  }

  // Config helpers
  int get maxItems => config['max_items'] ?? 10;
  bool get showAllLink => config['show_all_link'] ?? true;
  bool get showTimer => config['show_timer'] ?? false;
  bool get showPagination => config['show_pagination'] ?? false;
  int get itemsPerPage => config['items_per_page'] ?? 12;
}

/// Banner data
class BannerData {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? buttonText;
  final String? buttonLink;
  final String? linkUrl;
  final bool isAsset; // true if using local asset

  BannerData({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.buttonText,
    this.buttonLink,
    this.linkUrl,
    this.isAsset = false,
  });

  factory BannerData.fromJson(Map<String, dynamic> json) {
    return BannerData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      imageUrl: json['image_url'] ?? '',
      buttonText: json['button_text'],
      buttonLink: json['button_link'],
      linkUrl: json['link_url'],
    );
  }
}

/// Category data
class CategoryData {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? iconName;

  CategoryData({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.iconName,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: json['image_url'],
      iconName: json['icon_name'],
    );
  }
}

/// Brand data
class BrandData {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;

  BrandData({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
  });

  factory BrandData.fromJson(Map<String, dynamic> json) {
    return BrandData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'],
    );
  }
}

/// Flash deal configuration
class FlashDealData {
  final String id;
  final String title;
  final DateTime endTime;
  final List<String> productIds;
  final String? filterType;
  final String? filterValue;
  final int maxProducts;

  FlashDealData({
    required this.id,
    required this.title,
    required this.endTime,
    required this.productIds,
    this.filterType,
    this.filterValue,
    required this.maxProducts,
  });

  factory FlashDealData.fromJson(Map<String, dynamic> json) {
    return FlashDealData(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Flash Deals',
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now().add(const Duration(hours: 8)),
      productIds: (json['product_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      filterType: json['filter_type'],
      filterValue: json['filter_value'],
      maxProducts: json['max_products'] ?? 10,
    );
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (endTime.isAfter(now)) {
      return endTime.difference(now);
    }
    return Duration.zero;
  }

  bool get isActive => endTime.isAfter(DateTime.now());
}
