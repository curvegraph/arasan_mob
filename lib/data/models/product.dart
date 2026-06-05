import 'product_badge_settings.dart';

/// Animation types for product images
enum ImageAnimation {
  none,
  fadeIn,
  fadeOut,
  zoomIn,
  zoomOut,
  slideLeft,
  slideRight,
  bounce,
  pulse,
}

extension ImageAnimationExtension on ImageAnimation {
  static ImageAnimation fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'fadein':
        return ImageAnimation.fadeIn;
      case 'fadeout':
        return ImageAnimation.fadeOut;
      case 'zoomin':
        return ImageAnimation.zoomIn;
      case 'zoomout':
        return ImageAnimation.zoomOut;
      case 'slideleft':
        return ImageAnimation.slideLeft;
      case 'slideright':
        return ImageAnimation.slideRight;
      case 'bounce':
        return ImageAnimation.bounce;
      case 'pulse':
        return ImageAnimation.pulse;
      default:
        return ImageAnimation.none;
    }
  }
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double? offerPrice;
  final String description;
  final List<String> imageUrls;
  final String? thumbnailUrl;
  final String? gifUrl;
  final int stock;
  final bool isFeatured;
  final bool isActive;
  final Map<String, String> specs;
  final int displayOrder;
  final DateTime createdAt;
  final double rating;
  final int reviewCount;
  final ImageAnimation imageAnimation;
  final ProductBadgeSettings badges;
  /// Advertised offer percentage (e.g. 10 for "10% OFF"). Set by the backend
  /// from the linked offer. Prefer this over computing percent from prices —
  /// when a max-discount cap clamps the effective discount, the rupee saving
  /// no longer matches the advertised percent.
  final double? offerDiscountPercent;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.offerPrice,
    required this.description,
    required this.imageUrls,
    this.thumbnailUrl,
    this.gifUrl,
    required this.stock,
    this.isFeatured = false,
    this.isActive = true,
    this.specs = const {},
    this.displayOrder = 0,
    DateTime? createdAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageAnimation = ImageAnimation.none,
    this.badges = ProductBadgeSettings.useDefaults,
    this.offerDiscountPercent,
  }) : createdAt = createdAt ?? DateTime.now();

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    double? price,
    double? offerPrice,
    String? description,
    List<String>? imageUrls,
    String? thumbnailUrl,
    String? gifUrl,
    int? stock,
    bool? isFeatured,
    bool? isActive,
    Map<String, String>? specs,
    int? displayOrder,
    DateTime? createdAt,
    double? rating,
    int? reviewCount,
    ImageAnimation? imageAnimation,
    ProductBadgeSettings? badges,
    double? offerDiscountPercent,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gifUrl: gifUrl ?? this.gifUrl,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      specs: specs ?? this.specs,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageAnimation: imageAnimation ?? this.imageAnimation,
      badges: badges ?? this.badges,
      offerDiscountPercent: offerDiscountPercent ?? this.offerDiscountPercent,
    );
  }

  bool get isLowStock => stock > 0 && stock <= 5;
  bool get isOutOfStock => stock == 0;
  double get effectivePrice => offerPrice ?? price;
  /// Advertised offer percent. Trusts the backend's offer record over a
  /// price-ratio calculation, so a max-discount cap doesn't silently shrink
  /// the displayed badge (e.g. "10% off" stays "10% off" even when the cap
  /// limits the actual rupee saving to less).
  double get discountPercent {
    if (offerDiscountPercent != null && offerDiscountPercent! > 0) {
      return offerDiscountPercent!;
    }
    if (offerPrice != null) {
      return ((price - offerPrice!) / price * 100).round().toDouble();
    }
    return 0;
  }

  // Helper getters for product cards
  bool get hasDiscount => offerPrice != null && offerPrice! < price;
  double? get originalPrice => hasDiscount ? price : null;
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // JSON Serialization for Supabase
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      offerPrice: json['offer_price'] != null ? (json['offer_price'] as num).toDouble() : null,
      description: json['description'] as String? ?? '',
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      stock: json['stock'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      specs: (json['specs'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      imageAnimation: ImageAnimationExtension.fromString(json['image_animation'] as String?),
      badges: ProductBadgeSettings.fromJson(json),
      offerDiscountPercent: (json['offer_discount_percent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'offer_price': offerPrice,
      'description': description,
      'image_urls': imageUrls,
      'stock': stock,
      'is_featured': isFeatured,
      'is_active': isActive,
      'specs': specs,
      'display_order': displayOrder,
    };
  }
}
