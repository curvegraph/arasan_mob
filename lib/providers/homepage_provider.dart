import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/homepage_config.dart' as homepage_models;
import '../data/services/homepage_service.dart';

/// Provider for managing dynamic homepage configuration
/// Polls the backend for changes (Socket.IO bridge will replace this).
class HomepageProvider extends ChangeNotifier {
  final HomepageService _service = HomepageService();

  homepage_models.HomepageConfig? _config;
  bool _isLoading = false;
  String? _error;

  Timer? _pollTimer;
  bool _isSubscribed = false;

  // Getters
  homepage_models.HomepageConfig? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _config != null;

  // Individual section data getters
  List<homepage_models.HomepageSection> get sections => _config?.sections ?? [];
  List<homepage_models.BannerData> get banners => _config?.banners ?? [];
  List<homepage_models.CategoryData> get categories => _config?.categories ?? [];
  List<homepage_models.BrandData> get brands => _config?.brands ?? [];
  homepage_models.FlashDealData? get flashDeal => _config?.flashDeal;

  // Get section by key
  homepage_models.HomepageSection? getSectionByKey(String key) {
    try {
      return sections.firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  // Check if section is active
  bool isSectionActive(String key) {
    final section = getSectionByKey(key);
    return section != null;
  }

  // Get section config value
  T? getSectionConfig<T>(String key, String configKey, [T? defaultValue]) {
    final section = getSectionByKey(key);
    if (section == null) return defaultValue;
    return section.config[configKey] as T? ?? defaultValue;
  }

  /// Load homepage configuration from Supabase
  Future<void> loadHomepageConfig({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_config != null && !forceRefresh) {
      // Make sure realtime is wired even when we hit the cache, so admin
      // changes during this session reach the user immediately.
      subscribeToRealtimeUpdates();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use HomepageService which fetches directly from Supabase
      final supabaseConfig = await _service.getHomepageConfig();

      // Convert Supabase models to provider models
      // Use unique key combining id and display_order to ensure no duplicates
      _config = homepage_models.HomepageConfig(
        sections: supabaseConfig.sections.map((s) => homepage_models.HomepageSection(
          id: s.id,
          key: '${s.id}_${s.displayOrder}', // Unique key: id + displayOrder
          title: s.title,
          subtitle: null,
          type: s.type, // UI widget type: banner_carousel, product_grid, etc.
          config: s.config,
          filterType: s.config['filter_type'] as String? ?? 'all',
          filterValue: s.config['filter_value'] as String?,
          productIds: s.productIds,
          displayOrder: s.displayOrder,
          products: s.products, // backend-resolved products for this section
        )).toList(),
        banners: supabaseConfig.banners.map((b) => homepage_models.BannerData(
          id: b.id,
          title: b.title,
          subtitle: b.subtitle,
          imageUrl: b.imageUrl,
          linkUrl: b.linkUrl,
        )).toList(),
        categories: supabaseConfig.categories.map((c) => homepage_models.CategoryData(
          id: c.id,
          name: c.name,
          slug: c.slug ?? c.name.toLowerCase().replaceAll(' ', '-'),
          imageUrl: c.imageUrl,
        )).toList(),
        brands: supabaseConfig.brands.map((b) => homepage_models.BrandData(
          id: b.id,
          name: b.name,
          slug: b.slug ?? b.name.toLowerCase().replaceAll(' ', '-'),
          logoUrl: b.logoUrl,
        )).toList(),
        flashDeal: supabaseConfig.flashDeal,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[HomepageProvider] Error loading config: $e');
      // No fallback - show empty homepage until admin publishes one
      _config = homepage_models.HomepageConfig.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
      subscribeToRealtimeUpdates();
    }
  }

  /// Refresh homepage configuration
  Future<void> refresh() async {
    await loadHomepageConfig(forceRefresh: true);
  }

  /// Load individual components (for lazy loading)
  Future<List<homepage_models.BannerData>> loadBanners() async {
    try {
      final banners = await _service.getBanners();
      final bannerList = banners.map((b) => homepage_models.BannerData(
        id: b.id,
        title: b.title,
        subtitle: b.subtitle,
        imageUrl: b.imageUrl,
        linkUrl: b.linkUrl,
      )).toList();

      if (_config != null) {
        _config = homepage_models.HomepageConfig(
          sections: _config!.sections,
          banners: bannerList,
          categories: _config!.categories,
          brands: _config!.brands,
          flashDeal: _config!.flashDeal,
        );
        notifyListeners();
      }
      return bannerList;
    } catch (_) {
      return [];
    }
  }

  Future<List<homepage_models.CategoryData>> loadCategories() async {
    try {
      // Categories are loaded with homepage config
      return _config?.categories ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<homepage_models.BrandData>> loadBrands() async {
    try {
      final brands = await _service.getBrands();
      final brandList = brands.map((b) => homepage_models.BrandData(
        id: b.id,
        name: b.name,
        slug: b.slug ?? b.name.toLowerCase().replaceAll(' ', '-'),
        logoUrl: b.logoUrl,
      )).toList();

      if (_config != null) {
        _config = homepage_models.HomepageConfig(
          sections: _config!.sections,
          banners: _config!.banners,
          categories: _config!.categories,
          brands: brandList,
          flashDeal: _config!.flashDeal,
        );
        notifyListeners();
      }
      return brandList;
    } catch (_) {
      return [];
    }
  }

  Future<homepage_models.FlashDealData?> loadFlashDeal() async {
    try {
      final flashDeal = await _service.getActiveFlashDeal();
      if (flashDeal == null) return null;

      if (_config != null) {
        _config = homepage_models.HomepageConfig(
          sections: _config!.sections,
          banners: _config!.banners,
          categories: _config!.categories,
          brands: _config!.brands,
          flashDeal: flashDeal,
        );
        notifyListeners();
      }
      return flashDeal;
    } catch (_) {
      return null;
    }
  }

  /// Polling-based realtime substitute (until Socket.IO bridge is wired).
  void subscribeToRealtimeUpdates() {
    if (_isSubscribed) return;
    debugPrint('[HomepageProvider] Starting polling for homepage changes...');
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      loadHomepageConfig(forceRefresh: true);
    });
    _isSubscribed = true;
  }

  Future<void> unsubscribeFromRealtimeUpdates() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isSubscribed = false;
  }

  /// Clean up resources when provider is disposed
  @override
  void dispose() {
    unsubscribeFromRealtimeUpdates();
    super.dispose();
  }
}
