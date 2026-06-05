import 'package:flutter_test/flutter_test.dart';
import 'package:arasan_user/data/models/cart.dart';
import 'package:arasan_user/data/models/product.dart';

Product _makeProduct({double price = 1000, double? offerPrice}) {
  return Product(
    id: 'p1',
    name: 'Test Phone',
    brand: 'TestBrand',
    category: 'smartphones',
    price: price,
    offerPrice: offerPrice,
    description: 'A test product',
    imageUrls: ['https://example.com/img.jpg'],
    stock: 10,
  );
}

void main() {
  group('CartItem', () {
    test('totalPrice uses effectivePrice * quantity', () {
      final item = CartItem(
        id: 'c1',
        product: _makeProduct(price: 1000, offerPrice: 800),
        quantity: 2,
      );
      expect(item.totalPrice, 1600); // 800 * 2
    });

    test('savings calculates original - effective', () {
      final item = CartItem(
        id: 'c1',
        product: _makeProduct(price: 1000, offerPrice: 800),
        quantity: 2,
      );
      expect(item.savings, 400); // (1000*2) - (800*2)
    });

    test('copyWith updates quantity', () {
      final item = CartItem(
        id: 'c1',
        product: _makeProduct(),
        quantity: 1,
      );
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.id, 'c1');
    });

    test('copyWith updates isSavedForLater', () {
      final item = CartItem(
        id: 'c1',
        product: _makeProduct(),
      );
      expect(item.isSavedForLater, false);
      final saved = item.copyWith(isSavedForLater: true);
      expect(saved.isSavedForLater, true);
    });
  });

  group('Cart', () {
    test('empty cart has correct defaults', () {
      final cart = Cart();
      expect(cart.isEmpty, true);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0);
      expect(cart.deliveryCharge, 49); // under 999
      expect(cart.taxAmount, 0);
    });

    test('activeItems excludes savedForLater', () {
      final cart = Cart(items: [
        CartItem(id: 'c1', product: _makeProduct(), quantity: 1),
        CartItem(id: 'c2', product: _makeProduct(), quantity: 1, isSavedForLater: true),
        CartItem(id: 'c3', product: _makeProduct(), quantity: 1),
      ]);
      expect(cart.activeItems.length, 2);
      expect(cart.savedItems.length, 1);
    });

    test('itemCount sums quantities of active items', () {
      final cart = Cart(items: [
        CartItem(id: 'c1', product: _makeProduct(), quantity: 2),
        CartItem(id: 'c2', product: _makeProduct(), quantity: 3),
      ]);
      expect(cart.itemCount, 5);
    });

    test('subtotal sums active item prices', () {
      final cart = Cart(items: [
        CartItem(id: 'c1', product: _makeProduct(price: 500), quantity: 2),
        CartItem(id: 'c2', product: _makeProduct(price: 300), quantity: 1),
      ]);
      expect(cart.subtotal, 1300); // 500*2 + 300*1
    });

    test('free delivery when subtotal >= 999', () {
      final cart = Cart(items: [
        CartItem(id: 'c1', product: _makeProduct(price: 1000), quantity: 1),
      ]);
      expect(cart.deliveryCharge, 0);
    });

    test('delivery charge 49 when subtotal < 999', () {
      final cart = Cart(items: [
        CartItem(id: 'c1', product: _makeProduct(price: 500), quantity: 1),
      ]);
      expect(cart.deliveryCharge, 49);
    });

    test('tax is 18% of subtotal', () {
      final cart = Cart(items: [
        CartItem(id: 'c1', product: _makeProduct(price: 1000), quantity: 1),
      ]);
      expect(cart.taxAmount, 180); // 1000 * 0.18
    });

    test('totalAmount includes subtotal - coupon + delivery + tax', () {
      final cart = Cart(
        items: [
          CartItem(id: 'c1', product: _makeProduct(price: 1000), quantity: 1),
        ],
        couponDiscount: 100,
      );
      // subtotal=1000, coupon=-100, delivery=0 (>=999), tax=180
      expect(cart.totalAmount, 1080);
    });

    test('productDiscount tracks offer savings', () {
      final cart = Cart(items: [
        CartItem(
          id: 'c1',
          product: _makeProduct(price: 1000, offerPrice: 800),
          quantity: 2,
        ),
      ]);
      // original = 2000, subtotal = 1600
      expect(cart.productDiscount, 400);
    });

    test('totalSavings combines product + coupon discounts', () {
      final cart = Cart(
        items: [
          CartItem(
            id: 'c1',
            product: _makeProduct(price: 1000, offerPrice: 800),
            quantity: 1,
          ),
        ],
        couponDiscount: 50,
      );
      expect(cart.totalSavings, 250); // 200 product + 50 coupon
    });
  });
}
