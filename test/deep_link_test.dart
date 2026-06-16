import 'package:flutter_test/flutter_test.dart';
import 'package:arasan_user/core/routing/deep_link_handler.dart';
import 'package:arasan_user/core/utils/product_share_url.dart';
import 'package:arasan_user/data/models/product.dart';

void main() {
  group('DeepLinkHandler.locationFor', () {
    test('custom scheme product link → /shop/product route', () {
      final uri = Uri.parse('com.arasanmobiles.user://product/prod-001');
      expect(DeepLinkHandler.locationFor(uri), '/shop/product/prod-001');
    });

    test('custom scheme product link keeps the variant query', () {
      final uri =
          Uri.parse('com.arasanmobiles.user://product/prod-001?variant=v-9');
      expect(
        DeepLinkHandler.locationFor(uri),
        '/shop/product/prod-001?variant=v-9',
      );
    });

    test('web permalink (/product/<slug>/p/<id>) resolves the id after p', () {
      final uri = Uri.parse(
          'https://arasanmobiles.in/product/apple-iphone-15/p/prod-001?variant=v-9');
      expect(
        DeepLinkHandler.locationFor(uri),
        '/shop/product/prod-001?variant=v-9',
      );
    });

    test('OAuth callback is ignored', () {
      final uri = Uri.parse(
          'com.arasanmobiles.user://login-callback/?code=abc123');
      expect(DeepLinkHandler.locationFor(uri), isNull);
    });

    test('any link carrying ?code= is ignored (not a product link)', () {
      final uri =
          Uri.parse('com.arasanmobiles.user://product/prod-001?code=abc');
      expect(DeepLinkHandler.locationFor(uri), isNull);
    });

    test('unknown link shape returns null', () {
      final uri = Uri.parse('https://arasanmobiles.in/offers');
      expect(DeepLinkHandler.locationFor(uri), isNull);
    });
  });

  group('productShareUrl', () {
    final product = Product.fromJson({
      'id': 'prod-001',
      'name': 'iPhone 15',
      'brand': 'Apple',
      'category': 'smartphones',
      'price': 79999,
      'description': 'Latest iPhone',
      'image_urls': const <String>[],
      'stock': 10,
      'is_active': true,
      'created_at': '2025-01-01T00:00:00.000Z',
    });

    test('omits ?variant when no variant selected', () {
      final url = productShareUrl(product);
      expect(url, endsWith('/p/prod-001'));
      expect(url, isNot(contains('variant')));
    });

    test('appends ?variant=<id> when a variant is selected', () {
      final url = productShareUrl(product, variantId: 'v-9');
      expect(url, endsWith('/p/prod-001?variant=v-9'));
    });

    test('empty variant id is treated as no variant', () {
      final url = productShareUrl(product, variantId: '');
      expect(url, isNot(contains('variant')));
    });
  });
}
