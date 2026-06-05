import 'package:flutter/material.dart';
import '../data/models/banner.dart';
import '../data/services/homepage_service.dart';

class BannerProvider extends ChangeNotifier {
  final HomepageService _service = HomepageService();
  List<AppBanner> _banners = [];
  List<HomepageSection> _sections = [];
  bool _isLoading = false;

  List<AppBanner> get banners => _banners;
  List<HomepageSection> get sections => _sections;
  bool get isLoading => _isLoading;

  List<AppBanner> get activeBanners =>
      _banners.where((b) => b.isActive).toList();

  Future<void> loadBanners() async {
    _isLoading = true;
    notifyListeners();

    try {
      final config = await _service.getHomepageConfig();
      _banners = config.banners.asMap().entries.map((entry) {
        final b = entry.value;
        return AppBanner(
          id: b.id,
          title: b.title,
          imageUrl: b.imageUrl,
          linkUrl: b.linkUrl,
          position: BannerPosition.top,
          type: BannerType.promotional,
          isActive: true,
          displayOrder: entry.key,
        );
      }).toList();
    } catch (_) {
      _banners = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
