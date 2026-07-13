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

/// A purchasable variant of a product (a specific colour + storage/RAM combo).
/// Parsed from the product-detail endpoint's `variants[]` (each carries a
/// `variant_data` blob with colour/price/specs/images and a top-level stock).
class ProductVariant {
  final String id;
  final String? color;
  final double price;
  final double? offerPrice;
  /// Admin-set sale price for this variant (no active offer). When set and below
  /// [price] it's the selling price and [price] shows struck. An [offerPrice]
  /// wins over it. Parsed from `variant_data.sale_price`.
  final double? salePrice;
  final double? offerDiscountPercent;
  final List<String> imageUrls;
  final int stock;
  final Map<String, String> specs;

  ProductVariant({
    required this.id,
    this.color,
    required this.price,
    this.offerPrice,
    this.salePrice,
    this.offerDiscountPercent,
    this.imageUrls = const [],
    this.stock = 0,
    this.specs = const {},
  });

  String get ram => specs['ram'] ?? '';
  String get storage => specs['storage'] ?? '';

  /// Short label like "128GB + 16GB RAM" (falls back to colour).
  String get label {
    final parts = <String>[];
    if (storage.isNotEmpty) parts.add(storage);
    if (ram.isNotEmpty) parts.add('$ram RAM');
    if (parts.isNotEmpty) return parts.join(' + ');
    return color ?? 'Variant';
  }

  /// The discounted selling price when one applies, else null. An active offer
  /// ([offerPrice]) wins; otherwise the admin's [salePrice] is used. Only counts
  /// when actually below [price].
  double? get _discountedPrice {
    if (offerPrice != null && offerPrice! < price) return offerPrice;
    if (salePrice != null && salePrice! < price) return salePrice;
    return null;
  }

  double get effectivePrice => _discountedPrice ?? price;
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  bool get isOutOfStock => stock <= 0;

  /// True when a sale/offer applies — drives the struck original price display
  /// (both a sale price and an offer count here).
  bool get hasDiscount => _discountedPrice != null;

  /// OFFER percent only (for the "% OFF" badge). 0 for a plain sale price — a
  /// sale never produces a computed offer badge.
  double get discountPercent {
    if (offerDiscountPercent != null && offerDiscountPercent! > 0) {
      return offerDiscountPercent!;
    }
    if (offerPrice != null && offerPrice! < price && price > 0) {
      return ((price - offerPrice!) / price * 100).round().toDouble();
    }
    return 0;
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final vd = (json['variant_data'] is Map)
        ? Map<String, dynamic>.from(json['variant_data'] as Map)
        : <String, dynamic>{};
    final specs = (vd['specs'] is Map)
        ? (vd['specs'] as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString()))
        : <String, String>{};
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      color: vd['color']?.toString(),
      price: (vd['price'] as num?)?.toDouble() ?? 0,
      offerPrice: (vd['offer_price'] as num?)?.toDouble(),
      salePrice: (vd['sale_price'] as num?)?.toDouble(),
      offerDiscountPercent: (vd['offer_discount_percent'] as num?)?.toDouble(),
      imageUrls: (vd['image_urls'] as List<dynamic>?)?.cast<String>() ?? const [],
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      specs: specs,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double? offerPrice;
  /// The admin-set sale price for products WITHOUT an active offer. When set and
  /// below [price], it becomes the selling price and [price] is shown struck as
  /// the original. An active [offerPrice] takes priority over this. Parsed from
  /// the backend's `sale_price` column.
  final double? salePrice;
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
  /// When the admin curates a section by *variant* (e.g. Today's Offers can list
  /// two variants of the same product), the backend resolves that variant's
  /// price/image into the top-level fields and tags it with this id. The same
  /// product can therefore appear as multiple entries with distinct
  /// [selectedVariantId]s — dedupe on this (not [id]) so a curated variant
  /// isn't silently dropped.
  final String? selectedVariantId;
  /// Optional human label for the resolved variant (e.g. "128GB / Blue").
  final String? variantLabel;
  /// All selectable variants (colour + storage/RAM). Only populated by the
  /// product-detail fetch; empty in lightweight list responses.
  final List<ProductVariant> variants;
  /// The product's own colour (e.g. "Blue"). Combined with [specs] storage/RAM
  /// to show a variant-detail chip on homepage cards.
  final String? color;
  /// True when the product has selectable variants. Set by the backend on
  /// homepage cards so the card can show the variant-detail chip only for
  /// products that actually have variants.
  final bool hasVariants;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.offerPrice,
    this.salePrice,
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
    this.selectedVariantId,
    this.variantLabel,
    this.variants = const [],
    this.color,
    this.hasVariants = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    double? price,
    double? offerPrice,
    double? salePrice,
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
    String? selectedVariantId,
    String? variantLabel,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      salePrice: salePrice ?? this.salePrice,
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
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
      variantLabel: variantLabel ?? this.variantLabel,
      variants: variants ?? this.variants,
    );
  }

  bool get isLowStock => stock > 0 && stock <= 5;
  bool get isOutOfStock => stock == 0;

  /// The discounted selling price when one applies, else null. An active offer
  /// ([offerPrice]) wins; otherwise the admin's [salePrice] is used (products
  /// without an offer). Only counts when it's actually below [price].
  double? get _discountedPrice {
    if (offerPrice != null && offerPrice! < price) return offerPrice;
    if (salePrice != null && salePrice! < price) return salePrice;
    return null;
  }

  double get effectivePrice => _discountedPrice ?? price;

  /// Advertised OFFER percent — for the "% OFF" badge. This reflects ONLY an
  /// admin-created offer (offer_discount_percent, or a percent derived from the
  /// offer's offer_price). It is deliberately 0 for a plain sale price: a
  /// sale_price shows the struck original + sale price but NEVER a computed
  /// "% OFF" badge (offers are admin-set, not calculated from the sale).
  double get discountPercent {
    if (offerDiscountPercent != null && offerDiscountPercent! > 0) {
      return offerDiscountPercent!;
    }
    if (offerPrice != null && offerPrice! < price && price > 0) {
      return ((price - offerPrice!) / price * 100).round().toDouble();
    }
    return 0;
  }

  /// True when an admin OFFER applies (drives the "% OFF" badge). A sale price
  /// alone does not count here — see [hasDiscount] for the struck-price display.
  bool get hasOffer => discountPercent > 0;

  // Helper getters for product cards. [hasDiscount] drives the struck original
  // price + sale price display and is true for BOTH a sale price and an offer.
  bool get hasDiscount => _discountedPrice != null;
  double? get originalPrice => hasDiscount ? price : null;
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // JSON Serialization for Supabase
  factory Product.fromJson(Map<String, dynamic> json) {
    final specs = (json['specs'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? <String, String>{};
    final color = json['color']?.toString();
    final hasVariants = json['has_variants'] == true ||
        (json['variants'] is List && (json['variants'] as List).isNotEmpty);
    // The backend resolves `variant_label` on homepage/section/offer cards, but
    // the cart response carries no resolved label. Fall back to composing it
    // from the product's own colour + specs — same "colour · storage · RAM"
    // shape the backend uses — so the cart still shows which variant it is.
    // Only for products that actually have variants (plain products stay bare).
    final backendLabel = (json['variant_label'] as String?)?.trim();
    final variantLabel = (backendLabel != null && backendLabel.isNotEmpty)
        ? backendLabel
        : (hasVariants ? _composeSpecLabel(color, specs) : null);
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      offerPrice: json['offer_price'] != null ? (json['offer_price'] as num).toDouble() : null,
      salePrice: json['sale_price'] != null ? (json['sale_price'] as num).toDouble() : null,
      description: json['description'] as String? ?? '',
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      stock: json['stock'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      specs: specs,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      imageAnimation: ImageAnimationExtension.fromString(json['image_animation'] as String?),
      badges: ProductBadgeSettings.fromJson(json),
      offerDiscountPercent: (json['offer_discount_percent'] as num?)?.toDouble(),
      selectedVariantId: json['selected_variant_id'] as String?,
      variantLabel: variantLabel,
      variants: (json['variants'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => ProductVariant.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      color: color,
      // Backend tags homepage cards with this; also infer from an embedded
      // variants list when present.
      hasVariants: hasVariants,
    );
  }

  /// Compose a "colour · storage · RAM" label from the product's own colour and
  /// specs, mirroring the backend's `_variantLabel` helper. Returns null when
  /// there's nothing to show.
  static String? _composeSpecLabel(String? color, Map<String, String> specs) {
    final parts = <String>[];
    if ((color ?? '').trim().isNotEmpty) parts.add(color!.trim());
    final storage = specs['storage'];
    if ((storage ?? '').trim().isNotEmpty) parts.add(storage!.trim());
    final ram = specs['ram'];
    if ((ram ?? '').trim().isNotEmpty) parts.add('${ram!.trim()} RAM');
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'offer_price': offerPrice,
      'sale_price': salePrice,
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
