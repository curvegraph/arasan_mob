import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/store_settings.dart';
import '../data/services/store_settings_service.dart';

class StoreSettingsProvider extends ChangeNotifier {
  final _service = StoreSettingsService();
  Timer? _pollTimer;

  StoreSettings? _settings;
  bool _isLoading = false;
  String? _error;

  StoreSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Delivery / trust badges (existing consumers)
  double get freeDeliveryAbove => _settings?.freeDeliveryAbove ?? 0;
  double get deliveryChargeBase => _settings?.deliveryChargeBase ?? 0;

  /// Delivery charge for a given cart subtotal, applying the admin's rule:
  ///   * subtotal >= freeDeliveryAbove (and threshold > 0) -> 0
  ///   * otherwise -> deliveryChargeBase
  /// If both settings are 0/unset (e.g. before settings load), returns 0 so
  /// the user never sees a phantom charge based on stale defaults.
  double deliveryChargeFor(double subtotal) {
    final s = _settings;
    if (s == null) return 0;
    if (s.freeDeliveryAbove > 0 && subtotal >= s.freeDeliveryAbove) return 0;
    return s.deliveryChargeBase;
  }
  String get deliveryEstimateText => _settings?.deliveryEstimateText ?? '';
  String get trustBadge1Title => _settings?.trustBadge1Title ?? '';
  String get trustBadge1Subtitle => _settings?.trustBadge1Subtitle ?? '';
  String get trustBadge2Title => _settings?.trustBadge2Title ?? '';
  String get trustBadge2Subtitle => _settings?.trustBadge2Subtitle ?? '';
  String get trustBadge3Title => _settings?.trustBadge3Title ?? '';
  String get trustBadge3Subtitle => _settings?.trustBadge3Subtitle ?? '';

  // Payment methods — admin-controlled flags.
  // Default to `true` pre-load so the checkout screen doesn't briefly hide
  // everything while settings are fetching. Real values override once loaded.
  bool get codEnabled => _settings?.codEnabled ?? true;

  /// "Online Payment" (Razorpay) — single admin-controlled toggle. Falls back
  /// to the legacy upi/card OR if a row pre-dating the migration is loaded.
  bool get onlineEnabled =>
      _settings?.onlineEnabled ?? true;

  // Legacy getters retained for any non-checkout screens that still read them.
  bool get upiEnabled => _settings?.upiEnabled ?? true;
  bool get cardEnabled => _settings?.cardEnabled ?? true;
  String get upiId => _settings?.upiId ?? '';

  /// True if at least one method is enabled.
  bool get anyPaymentEnabled => codEnabled || onlineEnabled;

  // Tax — feeds cart calculations.
  TaxMode get taxMode => _settings?.taxMode ?? TaxMode.percent;
  double get taxRate => _settings?.taxRate ?? 18.0;
  double get taxAmount => _settings?.taxAmount ?? 0.0;
  bool get taxInclusive => _settings?.taxInclusive ?? false;

  /// Compute tax applied on top of a subtotal.
  double taxFor(double subtotal) =>
      _settings?.taxFor(subtotal) ??
      StoreSettings(
        taxMode: taxMode,
        taxRate: taxRate,
        taxAmount: this.taxAmount,
        taxInclusive: taxInclusive,
      ).taxFor(subtotal);

  String taxLabel() =>
      _settings?.taxLabel() ??
      StoreSettings(taxMode: taxMode, taxRate: taxRate).taxLabel();

  Future<void> loadSettings({bool force = false}) async {
    if (_settings != null && !force) {
      _ensureRealtime();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _service.getStoreSettings();
    } catch (e) {
      _error = 'Failed to load store settings: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
    _ensureRealtime();
  }

  /// Polling-based realtime substitute (until Socket.IO bridge is wired).
  void _ensureRealtime() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      try {
        _settings = await _service.getStoreSettings();
        notifyListeners();
      } catch (e) {
        debugPrint('Settings polling refresh failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }
}
