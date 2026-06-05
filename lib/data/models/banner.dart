enum BannerPosition { top, middle, bottom }
enum BannerType { promotional, offer, trending }

class AppBanner {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final BannerPosition position;
  final BannerType type;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  AppBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.position,
    required this.type,
    this.displayOrder = 0,
    this.isActive = true,
    DateTime? createdAt,
    this.expiresAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppBanner copyWith({
    String? title,
    String? imageUrl,
    String? linkUrl,
    BannerPosition? position,
    BannerType? type,
    int? displayOrder,
    bool? isActive,
    DateTime? expiresAt,
  }) {
    return AppBanner(
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      position: position ?? this.position,
      type: type ?? this.type,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class HomepageSection {
  final String id;
  final String title;
  final String type;
  final List<String> productIds;
  final int displayOrder;
  final bool isActive;

  HomepageSection({
    required this.id,
    required this.title,
    required this.type,
    required this.productIds,
    this.displayOrder = 0,
    this.isActive = true,
  });

  HomepageSection copyWith({
    String? title,
    List<String>? productIds,
    int? displayOrder,
    bool? isActive,
  }) {
    return HomepageSection(
      id: id,
      title: title ?? this.title,
      type: type,
      productIds: productIds ?? this.productIds,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
