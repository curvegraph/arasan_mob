/// Per-product badge override.
///
/// Each field is nullable: `null` = inherit from store default. Only the admin
/// app writes to these columns; the customer app reads them and merges with
/// `StoreSettingsProvider.trustBadge*` values.
class ProductBadgeSettings {
  final bool? badge1Enabled;
  final String? badge1Title;
  final String? badge1Subtitle;
  final bool? badge2Enabled;
  final String? badge2Title;
  final String? badge2Subtitle;
  final bool? badge3Enabled;
  final String? badge3Title;
  final String? badge3Subtitle;

  const ProductBadgeSettings({
    this.badge1Enabled,
    this.badge1Title,
    this.badge1Subtitle,
    this.badge2Enabled,
    this.badge2Title,
    this.badge2Subtitle,
    this.badge3Enabled,
    this.badge3Title,
    this.badge3Subtitle,
  });

  factory ProductBadgeSettings.fromJson(Map<String, dynamic> json) {
    return ProductBadgeSettings(
      badge1Enabled: json['badge_1_enabled'] as bool?,
      badge1Title: json['badge_1_title'] as String?,
      badge1Subtitle: json['badge_1_subtitle'] as String?,
      badge2Enabled: json['badge_2_enabled'] as bool?,
      badge2Title: json['badge_2_title'] as String?,
      badge2Subtitle: json['badge_2_subtitle'] as String?,
      badge3Enabled: json['badge_3_enabled'] as bool?,
      badge3Title: json['badge_3_title'] as String?,
      badge3Subtitle: json['badge_3_subtitle'] as String?,
    );
  }

  static const ProductBadgeSettings useDefaults = ProductBadgeSettings();
}
