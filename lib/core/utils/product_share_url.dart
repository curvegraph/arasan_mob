import '../../data/models/product.dart';

/// Public storefront origin — the web app that serves the OpenGraph meta tags
/// for product link previews. This is the LIVE domain (arasanmobiles.com is not
/// deployed); keep in sync with the SvelteKit site's deployed origin.
const String kStorefrontOrigin = 'https://arasanmobiles.in';

/// Lowercase + hyphenate + strip non-alphanumerics. Empty input → "".
/// Mirrors the web app's `toSlugPart`.
String _toSlugPart(String? input) {
  if (input == null || input.isEmpty) return '';
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'<[^>]*>'), ' ') // drop HTML tags
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
}

/// Flipkart-style permalink slug from brand + name + category + description
/// teaser, capped at 80 chars. Decorative — the server only reads the trailing
/// `/p/<id>` segment. Mirrors the web app's `slugifyProduct`.
String slugifyProduct(Product product) {
  final descPart =
      _toSlugPart(product.description).split('-').take(6).join('-');
  final parts = [
    _toSlugPart(product.brand),
    _toSlugPart(product.name),
    _toSlugPart(product.category),
    descPart,
  ].where((s) => s.isNotEmpty).toList();
  var slug = parts.join('-');
  if (slug.length > 80) slug = slug.substring(0, 80);
  slug = slug.replaceAll(RegExp(r'-+$'), '');
  return slug.isEmpty ? 'product' : slug;
}

/// Canonical, OpenGraph-enabled product URL — the same `/product/<slug>/p/<id>`
/// permalink the web app exposes, so a shared link unfurls with the product
/// image/title/description preview. Mirrors the web app's `productUrl`.
String productShareUrl(Product product) =>
    '$kStorefrontOrigin/product/${slugifyProduct(product)}/p/${product.id}';
