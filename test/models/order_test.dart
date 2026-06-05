import 'package:flutter_test/flutter_test.dart';
import 'package:arasan_user/data/models/order.dart';

void main() {
  group('OrderItem', () {
    final sampleJson = {
      'product_id': 'prod-001',
      'product_name': 'iPhone 15',
      'product_image': 'https://example.com/img.jpg',
      'quantity': 2,
      'unit_price': 74999,
    };

    test('fromJson creates correct OrderItem', () {
      final item = OrderItem.fromJson(sampleJson);
      expect(item.productId, 'prod-001');
      expect(item.productName, 'iPhone 15');
      expect(item.imageUrl, 'https://example.com/img.jpg');
      expect(item.quantity, 2);
      expect(item.price, 74999);
    });

    test('total calculates price * quantity', () {
      final item = OrderItem.fromJson(sampleJson);
      expect(item.total, 149998); // 74999 * 2
    });

    test('toJson produces correct map', () {
      final item = OrderItem.fromJson(sampleJson);
      final json = item.toJson('order-001');
      expect(json['order_id'], 'order-001');
      expect(json['product_id'], 'prod-001');
      expect(json['quantity'], 2);
      expect(json['unit_price'], 74999);
      expect(json['total_price'], 149998);
    });

    test('fromJson handles null product_image', () {
      final json = {...sampleJson, 'product_image': null};
      final item = OrderItem.fromJson(json);
      expect(item.imageUrl, '');
    });
  });

  group('OrderStatus', () {
    test('all statuses exist', () {
      expect(OrderStatus.values.length, 7);
      expect(OrderStatus.values, contains(OrderStatus.pending));
      expect(OrderStatus.values, contains(OrderStatus.confirmed));
      expect(OrderStatus.values, contains(OrderStatus.shipped));
      expect(OrderStatus.values, contains(OrderStatus.outForDelivery));
      expect(OrderStatus.values, contains(OrderStatus.delivered));
      expect(OrderStatus.values, contains(OrderStatus.cancelled));
      expect(OrderStatus.values, contains(OrderStatus.returned));
    });
  });
}
