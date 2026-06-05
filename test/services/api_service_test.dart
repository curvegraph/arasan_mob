import 'package:flutter_test/flutter_test.dart';
import 'package:arasan_user/data/services/api_service.dart';

void main() {
  group('ApiException', () {
    test('stores message and statusCode', () {
      final exception = ApiException('Not found', statusCode: 404);
      expect(exception.message, 'Not found');
      expect(exception.statusCode, 404);
      expect(exception.toString(), 'Not found');
    });

    test('stores errors', () {
      final exception = ApiException(
        'Validation failed',
        statusCode: 422,
        errors: {'email': 'Invalid email'},
      );
      expect(exception.errors, isNotNull);
      expect(exception.errors['email'], 'Invalid email');
    });

    test('works without optional fields', () {
      final exception = ApiException('Something went wrong');
      expect(exception.statusCode, isNull);
      expect(exception.errors, isNull);
    });
  });

  group('ApiService', () {
    test('is a singleton', () {
      final a = ApiService();
      final b = ApiService();
      expect(identical(a, b), true);
    });
  });
}
