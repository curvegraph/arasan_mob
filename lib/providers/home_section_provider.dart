import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/product.dart';
import '../data/models/home_section.dart';
import '../data/services/product_service.dart';

class HomeSectionProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<HomeSection> _sections = [];
  List<Product> _recentlyViewed = [];
  bool _isLoading = false;
  String? _error;

  static const int maxRecentlyViewed = 20;
  static const String _recentlyViewedKey = 'recently_viewed_products';

  List<HomeSection> get sections => _sections;
  List<Product> get recentlyViewed => _recentlyViewed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  HomeSectionProvider() {
    _loadRecentlyViewed();
  }

  Future<void> loadAllSections(List<Product> allProducts) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sections = [
        _buildFlashDealsSection(allProducts),
        _buildDealOfTheDaySection(allProducts),
        _buildBestSellingSection(allProducts),
        _buildNewArrivalsSection(allProducts),
        _buildTopRatedSection(allProducts),
        _buildTrendingSection(allProducts),
        _buildRecommendedSection(allProducts),
        _buildRecentlyViewedSection(),
      ].where((section) => section.hasProducts).toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load sections: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  HomeSection _buildFlashDealsSection(List<Product> allProducts) {
    // Flash deals: Products with discount > 20%
    final flashProducts = allProducts
        .where((p) => p.hasDiscount && p.discountPercent >= 20)
        .take(10)
        .toList();

    return HomeSection(
      id: SectionIds.flashDeals,
      title: 'Flash Deals',
      subtitle: 'Hurry! Limited time offers',
      products: flashProducts,
      layoutType: SectionLayoutType.carousel,
      cardStyle: SectionCardStyle.compact,
      showTimer: true,
      timerEndTime: DateTime.now().add(const Duration(hours: 8)),
      showViewAll: true,
      displayOrder: 1,
    );
  }

  HomeSection _buildDealOfTheDaySection(List<Product> allProducts) {
    // Deal of the day: Single best discount product
    final dealProducts = allProducts
        .where((p) => p.hasDiscount)
        .toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

    return HomeSection(
      id: SectionIds.dealOfTheDay,
      title: 'Deal of the Day',
      subtitle: 'Today\'s biggest discount',
      products: dealProducts.take(1).toList(),
      layoutType: SectionLayoutType.singleSpotlight,
      cardStyle: SectionCardStyle.large,
      showTimer: true,
      timerEndTime: _getEndOfDay(),
      showViewAll: false,
      displayOrder: 2,
    );
  }

  HomeSection _buildBestSellingSection(List<Product> allProducts) {
    // Best selling: Products with high review count
    final bestSelling = allProducts.toList()
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

    return HomeSection(
      id: SectionIds.bestSelling,
      title: 'Best Selling',
      subtitle: 'Our most popular products',
      products: bestSelling.take(10).toList(),
      layoutType: SectionLayoutType.carousel,
      cardStyle: SectionCardStyle.compact,
      showViewAll: true,
      displayOrder: 3,
    );
  }

  HomeSection _buildNewArrivalsSection(List<Product> allProducts) {
    // New arrivals: Recently added products
    final newArrivals = allProducts.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return HomeSection(
      id: SectionIds.newArrivals,
      title: 'New Arrivals',
      subtitle: 'Just landed',
      products: newArrivals.take(10).toList(),
      layoutType: SectionLayoutType.carousel,
      cardStyle: SectionCardStyle.compact,
      showViewAll: true,
      displayOrder: 4,
    );
  }

  HomeSection _buildTopRatedSection(List<Product> allProducts) {
    // Top rated: Highest rated products
    final topRated = allProducts.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return HomeSection(
      id: SectionIds.topRated,
      title: 'Top Rated',
      subtitle: 'Highly rated by customers',
      products: topRated.where((p) => p.rating >= 4.0).take(10).toList(),
      layoutType: SectionLayoutType.carousel,
      cardStyle: SectionCardStyle.compact,
      showViewAll: true,
      displayOrder: 5,
    );
  }

  HomeSection _buildTrendingSection(List<Product> allProducts) {
    // Trending: Featured products
    final trending = allProducts.where((p) => p.isFeatured).take(10).toList();

    return HomeSection(
      id: SectionIds.trending,
      title: 'Trending Now',
      subtitle: 'What\'s hot right now',
      products: trending,
      layoutType: SectionLayoutType.carousel,
      cardStyle: SectionCardStyle.compact,
      showViewAll: true,
      displayOrder: 6,
    );
  }

  HomeSection _buildRecommendedSection(List<Product> allProducts) {
    // Recommended: Mix of featured and discounted
    final recommended = allProducts
        .where((p) => p.isFeatured || p.hasDiscount)
        .take(10)
        .toList();

    return HomeSection(
      id: SectionIds.recommended,
      title: 'Recommended for You',
      subtitle: 'Based on your interests',
      products: recommended,
      layoutType: SectionLayoutType.carousel,
      cardStyle: SectionCardStyle.compact,
      showViewAll: true,
      displayOrder: 7,
    );
  }

  HomeSection _buildRecentlyViewedSection() {
    return HomeSection(
      id: SectionIds.recentlyViewed,
      title: 'Recently Viewed',
      subtitle: 'Continue where you left off',
      products: _recentlyViewed,
      layoutType: SectionLayoutType.carousel,
      cardStyle: SectionCardStyle.compact,
      showViewAll: false,
      displayOrder: 8,
    );
  }

  DateTime _getEndOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  // Recently Viewed Management
  Future<void> _loadRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentlyViewedKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _recentlyViewed = jsonList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading recently viewed: $e');
    }
  }

  Future<void> addToRecentlyViewed(Product product) async {
    // Remove if already exists
    _recentlyViewed.removeWhere((p) => p.id == product.id);

    // Add to beginning
    _recentlyViewed.insert(0, product);

    // Keep only max items
    if (_recentlyViewed.length > maxRecentlyViewed) {
      _recentlyViewed = _recentlyViewed.take(maxRecentlyViewed).toList();
    }

    // Update the recently viewed section
    final sectionIndex = _sections.indexWhere((s) => s.id == SectionIds.recentlyViewed);
    if (sectionIndex != -1) {
      _sections[sectionIndex] = _buildRecentlyViewedSection();
    }

    notifyListeners();
    await _saveRecentlyViewed();
  }

  Future<void> _saveRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _recentlyViewed.map((p) => {
        'id': p.id,
        'name': p.name,
        'brand': p.brand,
        'category': p.category,
        'price': p.price,
        'offer_price': p.offerPrice,
        'description': p.description,
        'image_urls': p.imageUrls,
        'stock': p.stock,
        'is_featured': p.isFeatured,
        'is_active': p.isActive,
        'rating': p.rating,
        'review_count': p.reviewCount,
      }).toList();
      await prefs.setString(_recentlyViewedKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving recently viewed: $e');
    }
  }

  Future<void> clearRecentlyViewed() async {
    _recentlyViewed.clear();

    // Update the section
    final sectionIndex = _sections.indexWhere((s) => s.id == SectionIds.recentlyViewed);
    if (sectionIndex != -1) {
      _sections[sectionIndex] = _buildRecentlyViewedSection();
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentlyViewedKey);
    } catch (e) {
      debugPrint('Error clearing recently viewed: $e');
    }
  }

  HomeSection? getSectionById(String id) {
    try {
      return _sections.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
