import 'product.dart';

enum SectionLayoutType {
  carousel,
  grid,
  singleSpotlight,
}

enum SectionCardStyle {
  compact,
  standard,
  large,
}

class HomeSection {
  final String id;
  final String title;
  final String? subtitle;
  final List<Product> products;
  final SectionLayoutType layoutType;
  final SectionCardStyle cardStyle;
  final bool showBackground;
  final String? backgroundColor;
  final bool showTimer;
  final DateTime? timerEndTime;
  final bool showViewAll;
  final String? viewAllRoute;
  final int displayOrder;
  final bool isActive;

  HomeSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.products = const [],
    this.layoutType = SectionLayoutType.carousel,
    this.cardStyle = SectionCardStyle.compact,
    this.showBackground = false,
    this.backgroundColor,
    this.showTimer = false,
    this.timerEndTime,
    this.showViewAll = true,
    this.viewAllRoute,
    this.displayOrder = 0,
    this.isActive = true,
  });

  HomeSection copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<Product>? products,
    SectionLayoutType? layoutType,
    SectionCardStyle? cardStyle,
    bool? showBackground,
    String? backgroundColor,
    bool? showTimer,
    DateTime? timerEndTime,
    bool? showViewAll,
    String? viewAllRoute,
    int? displayOrder,
    bool? isActive,
  }) {
    return HomeSection(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      products: products ?? this.products,
      layoutType: layoutType ?? this.layoutType,
      cardStyle: cardStyle ?? this.cardStyle,
      showBackground: showBackground ?? this.showBackground,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showTimer: showTimer ?? this.showTimer,
      timerEndTime: timerEndTime ?? this.timerEndTime,
      showViewAll: showViewAll ?? this.showViewAll,
      viewAllRoute: viewAllRoute ?? this.viewAllRoute,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get hasProducts => products.isNotEmpty;
  int get productCount => products.length;
}

// Predefined section IDs
class SectionIds {
  static const String flashDeals = 'flash_deals';
  static const String dealOfTheDay = 'deal_of_the_day';
  static const String bestSelling = 'best_selling';
  static const String shopByBrand = 'shop_by_brand';
  static const String shopByBudget = 'shop_by_budget';
  static const String newArrivals = 'new_arrivals';
  static const String recommended = 'recommended';
  static const String topRated = 'top_rated';
  static const String trending = 'trending';
  static const String recentlyViewed = 'recently_viewed';
}
