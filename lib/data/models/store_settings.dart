/// Tax configuration mode.
enum TaxMode { none, percent, fixed }

TaxMode taxModeFromDb(String? raw) {
  switch (raw) {
    case 'none':
      return TaxMode.none;
    case 'fixed':
      return TaxMode.fixed;
    case 'percent':
    default:
      return TaxMode.percent;
  }
}

class StoreSettings {
  final String storeName;
  final String storeEmail;
  final String storePhone;
  final String storeAddress;
  final String? storeLogo;
  final String gstNumber;
  final double gstPercent;
  final double deliveryChargeBase;
  final double freeDeliveryAbove;
  final bool codEnabled;
  final bool onlineEnabled;
  // Legacy flags retained for backward-compat with older admin builds.
  final bool upiEnabled;
  final bool cardEnabled;
  final String upiId;
  final String deliveryEstimateText;
  final String trustBadge1Title;
  final String trustBadge1Subtitle;
  final String trustBadge2Title;
  final String trustBadge2Subtitle;
  final String trustBadge3Title;
  final String trustBadge3Subtitle;

  final TaxMode taxMode;
  final double taxRate;
  final double taxAmount;
  final bool taxInclusive;

  StoreSettings({
    this.storeName = '',
    this.storeEmail = '',
    this.storePhone = '',
    this.storeAddress = '',
    this.storeLogo,
    this.gstNumber = '',
    this.gstPercent = 18.0,
    this.deliveryChargeBase = 0.0,
    this.freeDeliveryAbove = 0.0,
    this.codEnabled = false,
    this.onlineEnabled = true,
    this.upiEnabled = false,
    this.cardEnabled = false,
    this.upiId = '',
    this.deliveryEstimateText = '',
    this.trustBadge1Title = 'Free Shipping',
    this.trustBadge1Subtitle = 'Over ₹999',
    this.trustBadge2Title = '7-Day Easy',
    this.trustBadge2Subtitle = 'Returns',
    this.trustBadge3Title = 'Genuine',
    this.trustBadge3Subtitle = 'Products',
    this.taxMode = TaxMode.percent,
    this.taxRate = 18.0,
    this.taxAmount = 0.0,
    this.taxInclusive = false,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    final gstPct = (json['gst_percent'] as num?)?.toDouble() ?? 18.0;
    return StoreSettings(
      storeName: json['store_name'] as String? ?? '',
      storeEmail: json['store_email'] as String? ?? '',
      storePhone: json['store_phone'] as String? ?? '',
      storeAddress: json['store_address'] as String? ?? '',
      storeLogo: json['store_logo'] as String?,
      gstNumber: json['gst_number'] as String? ?? '',
      gstPercent: gstPct,
      deliveryChargeBase: (json['delivery_charge_base'] as num?)?.toDouble() ?? 0.0,
      freeDeliveryAbove: (json['free_delivery_above'] as num?)?.toDouble() ?? 0.0,
      codEnabled: json['cod_enabled'] as bool? ?? false,
      onlineEnabled: json['online_enabled'] as bool? ??
          ((json['upi_enabled'] as bool? ?? true) ||
              (json['card_enabled'] as bool? ?? true)),
      upiEnabled: json['upi_enabled'] as bool? ?? true,
      cardEnabled: json['card_enabled'] as bool? ?? true,
      upiId: json['upi_id'] as String? ?? '',
      deliveryEstimateText: json['delivery_estimate_text'] as String? ?? '',
      // Sensible defaults so trust badges render even before the admin
      // configures them in store_settings. Per-product overrides still win.
      trustBadge1Title: json['trust_badge_1_title'] as String? ?? 'Free Shipping',
      trustBadge1Subtitle: json['trust_badge_1_subtitle'] as String? ?? 'Over ₹999',
      trustBadge2Title: json['trust_badge_2_title'] as String? ?? '7-Day Easy',
      trustBadge2Subtitle: json['trust_badge_2_subtitle'] as String? ?? 'Returns',
      trustBadge3Title: json['trust_badge_3_title'] as String? ?? 'Genuine',
      trustBadge3Subtitle: json['trust_badge_3_subtitle'] as String? ?? 'Products',
      taxMode: taxModeFromDb(json['tax_mode'] as String?),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? gstPct,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      taxInclusive: json['tax_inclusive'] as bool? ?? false,
    );
  }

  /// Amount of tax to add on top of a subtotal.
  double taxFor(double subtotal) {
    if (taxInclusive) return 0;
    switch (taxMode) {
      case TaxMode.none:
        return 0;
      case TaxMode.percent:
        return subtotal * (taxRate / 100.0);
      case TaxMode.fixed:
        return taxAmount;
    }
  }

  /// Human-readable label for a tax line.
  String taxLabel() {
    switch (taxMode) {
      case TaxMode.none:
        return 'Tax';
      case TaxMode.percent:
        return 'Tax (${taxRate.toStringAsFixed(taxRate.truncateToDouble() == taxRate ? 0 : 2)}%)';
      case TaxMode.fixed:
        return 'Tax';
    }
  }
}
