import 'package:flutter_test/flutter_test.dart';
import 'package:arasan_user/data/models/product.dart';

void main() {
  group('Product', () {
    final sampleJson = {
      'id': 'prod-001',
      'name': 'iPhone 15',
      'brand': 'Apple',
      'category': 'smartphones',
      'price': 79999,
      'offer_price': 74999,
      'description': 'Latest iPhone',
      'image_urls': ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
      'stock': 10,
      'is_featured': true,
      'is_active': true,
      'specs': {'RAM': '8GB', 'Storage': '256GB'},
      'display_order': 1,
      'created_at': '2025-01-01T00:00:00.000Z',
      'rating': 4.5,
      'review_count': 120,
      'image_animation': 'fadeIn',
    };

    test('fromJson creates correct Product', () {
      final product = Product.fromJson(sampleJson);

      expect(product.id, 'prod-001');
      expect(product.name, 'iPhone 15');
      expect(product.brand, 'Apple');
      expect(product.price, 79999);
      expect(product.offerPrice, 74999);
      expect(product.imageUrls.length, 2);
      expect(product.stock, 10);
      expect(product.isFeatured, true);
      expect(product.specs['RAM'], '8GB');
      expect(product.rating, 4.5);
      expect(product.reviewCount, 120);
      expect(product.imageAnimation, ImageAnimation.fadeIn);
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'id': 'prod-002',
        'name': 'Basic Phone',
        'brand': 'Nokia',
        'category': 'feature-phones',
        'price': 2999,
      };

      final product = Product.fromJson(minimalJson);

      expect(product.offerPrice, isNull);
      expect(product.description, '');
      expect(product.imageUrls, isEmpty);
      expect(product.stock, 0);
      expect(product.isFeatured, false);
      expect(product.rating, 0.0);
      expect(product.reviewCount, 0);
    });

    test('toJson produces correct map', () {
      final product = Product.fromJson(sampleJson);
      final json = product.toJson();

      expect(json['name'], 'iPhone 15');
      expect(json['brand'], 'Apple');
      expect(json['price'], 79999);
      expect(json['offer_price'], 74999);
      expect(json['stock'], 10);
      expect(json['is_featured'], true);
    });

    test('effectivePrice returns offerPrice when available', () {
      final product = Product.fromJson(sampleJson);
      expect(product.effectivePrice, 74999);
    });

    test('effectivePrice returns price when no offer', () {
      final product = Product.fromJson({
        ...sampleJson,
        'offer_price': null,
      });
      expect(product.effectivePrice, 79999);
    });

    test('discountPercent calculates correctly', () {
      final product = Product.fromJson(sampleJson);
      // (79999 - 74999) / 79999 * 100 = 6.25 → rounds to 6
      expect(product.discountPercent, 6.0);
    });

    test('hasDiscount is true when offerPrice < price', () {
      final product = Product.fromJson(sampleJson);
      expect(product.hasDiscount, true);
    });

    test('isLowStock when stock between 1 and 5', () {
      final product = Product.fromJson({...sampleJson, 'stock': 3});
      expect(product.isLowStock, true);
      expect(product.isOutOfStock, false);
    });

    test('isOutOfStock when stock is 0', () {
      final product = Product.fromJson({...sampleJson, 'stock': 0});
      expect(product.isOutOfStock, true);
      expect(product.isLowStock, false);
    });

    test('copyWith preserves unchanged fields', () {
      final original = Product.fromJson(sampleJson);
      final updated = original.copyWith(price: 69999, stock: 5);

      expect(updated.price, 69999);
      expect(updated.stock, 5);
      expect(updated.name, original.name);
      expect(updated.brand, original.brand);
      expect(updated.id, original.id);
    });

    test('imageUrl returns first image or empty string', () {
      final product = Product.fromJson(sampleJson);
      expect(product.imageUrl, 'https://example.com/img1.jpg');

      final noImages = Product.fromJson({...sampleJson, 'image_urls': []});
      expect(noImages.imageUrl, '');
    });
  });

  group('ImageAnimation', () {
    test('fromString parses all animation types', () {
      expect(ImageAnimationExtension.fromString('fadein'), ImageAnimation.fadeIn);
      expect(ImageAnimationExtension.fromString('zoomIn'), ImageAnimation.zoomIn);
      expect(ImageAnimationExtension.fromString('bounce'), ImageAnimation.bounce);
      expect(ImageAnimationExtension.fromString(null), ImageAnimation.none);
      expect(ImageAnimationExtension.fromString('invalid'), ImageAnimation.none);
    });
  });
}
