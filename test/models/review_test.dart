import 'package:flutter_test/flutter_test.dart';
import 'package:arasan_user/data/models/review.dart';

void main() {
  group('Review', () {
    test('creates with defaults', () {
      final review = Review(
        id: 'r1',
        productId: 'p1',
        userId: 'u1',
        userName: 'Test User',
        rating: 4.5,
        comment: 'Great phone!',
      );

      expect(review.photos, isEmpty);
      expect(review.isVerifiedPurchase, false);
      expect(review.helpfulCount, 0);
      expect(review.createdAt, isNotNull);
    });

    test('copyWith updates specified fields', () {
      final review = Review(
        id: 'r1',
        productId: 'p1',
        userId: 'u1',
        userName: 'Test User',
        rating: 3.0,
        comment: 'OK phone',
      );

      final updated = review.copyWith(
        rating: 5.0,
        comment: 'Actually great!',
        helpfulCount: 10,
      );

      expect(updated.rating, 5.0);
      expect(updated.comment, 'Actually great!');
      expect(updated.helpfulCount, 10);
      expect(updated.id, 'r1'); // unchanged
      expect(updated.userId, 'u1'); // unchanged
    });
  });

  group('RatingSummary', () {
    test('getPercentage calculates correctly', () {
      final summary = RatingSummary(
        averageRating: 4.0,
        totalReviews: 100,
        starCounts: {5: 40, 4: 30, 3: 20, 2: 5, 1: 5},
      );

      expect(summary.getPercentage(5), 40.0);
      expect(summary.getPercentage(4), 30.0);
      expect(summary.getPercentage(1), 5.0);
    });

    test('getPercentage returns 0 when no reviews', () {
      final summary = RatingSummary(
        averageRating: 0,
        totalReviews: 0,
        starCounts: {},
      );

      expect(summary.getPercentage(5), 0);
    });

    test('getPercentage returns 0 for missing star count', () {
      final summary = RatingSummary(
        averageRating: 5.0,
        totalReviews: 10,
        starCounts: {5: 10},
      );

      expect(summary.getPercentage(1), 0);
    });
  });
}
