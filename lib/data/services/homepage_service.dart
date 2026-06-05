import '../models/homepage_config.dart';
import 'api_service.dart';

/// Service for fetching homepage configuration via the backend.
class HomepageService {
  final ApiService _api = ApiService();

  Future<HomepageConfig> getHomepageConfig() async {
    final results = await Future.wait([
      getSections(),
      getBanners().catchError((_) => <BannerData>[]),
      getCategories().catchError((_) => <CategoryData>[]),
      getBrands().catchError((_) => <BrandData>[]),
      getActiveFlashDeal().catchError((_) => null),
    ]);

    return HomepageConfig(
      sections: results[0] as List<HomepageSection>,
      banners: results[1] as List<BannerData>,
      categories: results[2] as List<CategoryData>,
      brands: results[3] as List<BrandData>,
      flashDeal: results[4] as FlashDealData?,
    );
  }

  Future<List<BannerData>> getBanners() async {
    try {
      final data = await _api.get('/homepage/banners');
      final list = (data is Map && data['banners'] is List)
          ? data['banners'] as List
          : (data is List ? data : const []);
      return list
          .whereType<Map>()
          .map((e) => BannerData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CategoryData>> getCategories({int limit = 8}) async {
    try {
      final data = await _api.get('/categories/root',
          queryParams: {'limit': '$limit'});
      final list = (data is Map && data['categories'] is List)
          ? data['categories'] as List
          : (data is List ? data : const []);
      return list
          .whereType<Map>()
          .map((e) => CategoryData.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<BrandData>> getBrands({int limit = 8}) async {
    try {
      final data = await _api.get('/homepage/brands',
          queryParams: {'limit': '$limit'});
      final list = (data is Map && data['brands'] is List)
          ? data['brands'] as List
          : (data is List ? data : const []);
      if (list.isEmpty) return [];
      // Backend returns either {id,name,slug,...} maps or plain strings
      return list.map((e) {
        if (e is Map) {
          return BrandData.fromJson(Map<String, dynamic>.from(e));
        }
        final name = e.toString();
        return BrandData(id: name.toLowerCase(), name: name, slug: name);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<FlashDealData?> getActiveFlashDeal() async {
    try {
      final data = await _api.get('/homepage/flash-deal');
      if (data is Map) {
        if (data['flash_deal'] is Map) {
          return FlashDealData.fromJson(
              Map<String, dynamic>.from(data['flash_deal'] as Map));
        }
        if (data['id'] != null) {
          return FlashDealData.fromJson(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<HomepageSection>> getSections() async {
    try {
      final data = await _api.get('/homepage/sections');
      final list = (data is Map && data['sections'] is List)
          ? data['sections'] as List
          : (data is List ? data : const []);
      return list
          .whereType<Map>()
          .map((e) => HomepageSection.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
