import 'package:flutter/material.dart';
import '../data/models/offer.dart';
import '../data/services/api_service.dart';

class OfferProvider extends ChangeNotifier {
  List<Offer> _offers = [];
  List<Coupon> _coupons = [];
  bool _isLoading = false;
  String? _error;

  final ApiService _api = ApiService();

  List<Offer> get offers => _offers;
  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Offer> get activeOffers =>
      _offers.where((o) => o.isActive && !o.isExpired).toList();
  List<Offer> get expiredOffers =>
      _offers.where((o) => o.isExpired || !o.isActive).toList();

  List<Coupon> get activeCoupons =>
      _coupons.where((c) => c.isActive && !c.isExpired && !c.isLimitReached).toList();
  List<Coupon> get expiredCoupons =>
      _coupons.where((c) => c.isExpired || !c.isActive || c.isLimitReached).toList();

  List<Offer> getOffersForProduct(String productId) =>
      _offers.where((o) => o.productId == productId && o.isActive && !o.isExpired).toList();

  Future<void> loadOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.get('/offers'),
        _api.get('/coupons/active'),
      ]);

      final offersPayload = results[0];
      final couponsPayload = results[1];

      final offersList = offersPayload is Map && offersPayload['offers'] is List
          ? offersPayload['offers'] as List
          : (offersPayload is List ? offersPayload : const []);
      final couponsList = couponsPayload is List
          ? couponsPayload
          : (couponsPayload is Map && couponsPayload['coupons'] is List
              ? couponsPayload['coupons'] as List
              : const []);

      _offers = offersList
          .whereType<Map>()
          .map((json) => Offer.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      _coupons = couponsList
          .whereType<Map>()
          .map((json) => Coupon.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      _error = 'Failed to load offers';
      debugPrint('OfferProvider.loadOffers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void addOffer(Offer offer) {
    _offers.add(offer);
    notifyListeners();
  }

  void addCoupon(Coupon coupon) {
    _coupons.add(coupon);
    notifyListeners();
  }

  void toggleOffer(String id) {
    final index = _offers.indexWhere((o) => o.id == id);
    if (index != -1) {
      _offers[index] = _offers[index].copyWith(isActive: !_offers[index].isActive);
      notifyListeners();
    }
  }

  void toggleCoupon(String id) {
    final index = _coupons.indexWhere((c) => c.id == id);
    if (index != -1) {
      _coupons[index] = _coupons[index].copyWith(isActive: !_coupons[index].isActive);
      notifyListeners();
    }
  }

  void deleteOffer(String id) {
    _offers.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  void deleteCoupon(String id) {
    _coupons.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
