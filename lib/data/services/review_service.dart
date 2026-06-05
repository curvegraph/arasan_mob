import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _api = ApiService();
  final SupabaseClient _auth = Supabase.instance.client;
  static const _bucket = 'review-images';

  Review _toReview(Map<String, dynamic> m, {String? defaultUserName}) {
    final customer = (m['customer'] is Map)
        ? Map<String, dynamic>.from(m['customer'] as Map)
        : (m['customers'] is Map ? Map<String, dynamic>.from(m['customers'] as Map) : null);
    final userName = customer?['name'] as String? ?? defaultUserName ?? 'Customer';
    return Review(
      id: m['id'] as String,
      productId: m['product_id'] as String,
      userId: m['customer_id'] as String? ?? '',
      userName: userName,
      rating: (m['rating'] as num).toDouble(),
      comment: m['review'] as String? ?? '',
      photos: (m['photos'] as List?)?.cast<String>() ?? const [],
      isVerifiedPurchase: m['is_verified_purchase'] as bool? ?? false,
      helpfulCount: (m['helpful_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<({List<Review> reviews, RatingSummary summary})> getProductReviews(
    String productId,
  ) async {
    final data = await _api.get('/reviews/product/$productId',
        queryParams: {'limit': '100'});
    final list = (data is Map && data['reviews'] is List)
        ? data['reviews'] as List
        : const [];
    final reviews = list
        .whereType<Map>()
        .map((e) => _toReview(Map<String, dynamic>.from(e)))
        .toList();

    RatingSummary summary;
    if (data is Map && data['summary'] is Map) {
      final s = Map<String, dynamic>.from(data['summary'] as Map);
      final ratingCounts = (s['ratingCounts'] is Map)
          ? Map<String, dynamic>.from(s['ratingCounts'] as Map)
          : <String, dynamic>{};
      final counts = <int, int>{
        1: (ratingCounts['1'] as num?)?.toInt() ?? 0,
        2: (ratingCounts['2'] as num?)?.toInt() ?? 0,
        3: (ratingCounts['3'] as num?)?.toInt() ?? 0,
        4: (ratingCounts['4'] as num?)?.toInt() ?? 0,
        5: (ratingCounts['5'] as num?)?.toInt() ?? 0,
      };
      summary = RatingSummary(
        averageRating: (s['averageRating'] as num?)?.toDouble() ?? 0,
        totalReviews: (s['totalReviews'] as num?)?.toInt() ?? reviews.length,
        starCounts: counts,
      );
    } else {
      summary = _summarize(reviews);
    }
    return (reviews: reviews, summary: summary);
  }

  Future<Set<String>> getMyHelpfulVotes(List<String> reviewIds) async {
    if (reviewIds.isEmpty) return <String>{};
    if (_auth.auth.currentUser == null) return <String>{};

    try {
      final data = await _api.post('/reviews/my-helpful-votes',
          body: {'reviewIds': reviewIds}, requireAuth: true);
      final list = (data is Map && data['reviewIds'] is List)
          ? data['reviewIds'] as List
          : const [];
      return list.map((e) => e.toString()).toSet();
    } on ApiException {
      return <String>{};
    }
  }

  Future<Review?> getMyReviewForProduct(String productId) async {
    if (_auth.auth.currentUser == null) return null;
    try {
      final myItems = await getMyReviews();
      for (final item in myItems) {
        if (item.review.productId == productId) {
          return item.review;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasDeliveredPurchase(String productId) async {
    if (_auth.auth.currentUser == null) return false;
    try {
      final data = await _api.get('/reviews/can-review/$productId',
          requireAuth: true);
      if (data is Map) {
        return (data['canReview'] == true && data['isVerifiedPurchase'] == true);
      }
      return false;
    } on ApiException {
      return false;
    }
  }

  Future<Review> addReview({
    required String productId,
    required int rating,
    required String review,
    String? title,
    List<String> photos = const [],
  }) async {
    final user = _auth.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final verified = await hasDeliveredPurchase(productId);
    if (!verified) throw const ReviewNotEligibleException();

    final res = await _api.post('/reviews/product/$productId',
        body: {
          'rating': rating,
          'review': review,
          if (title != null && title.isNotEmpty) 'title': title,
          if (photos.isNotEmpty) 'photos': photos,
        },
        requireAuth: true);

    final m = (res is Map && res['review'] is Map)
        ? Map<String, dynamic>.from(res['review'] as Map)
        : Map<String, dynamic>.from(res as Map);
    return _toReview(m, defaultUserName: 'You');
  }

  Future<Review> updateReview({
    required String reviewId,
    int? rating,
    String? review,
    String? title,
    List<String>? photos,
  }) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (review != null) body['review'] = review;
    if (title != null) body['title'] = title;
    if (photos != null) body['photos'] = photos;

    final res = await _api.patch('/reviews/$reviewId',
        body: body, requireAuth: true);
    final m = (res is Map && res['review'] is Map)
        ? Map<String, dynamic>.from(res['review'] as Map)
        : Map<String, dynamic>.from(res as Map);
    return _toReview(m, defaultUserName: 'You');
  }

  Future<void> deleteReview(String reviewId) async {
    await _api.delete('/reviews/$reviewId', requireAuth: true);
  }

  Future<bool> toggleHelpful(String reviewId) async {
    final res = await _api.post('/reviews/$reviewId/helpful', requireAuth: true);
    if (res is Map && res['helpful'] is bool) return res['helpful'] as bool;
    return false;
  }

  /// Upload review photos via the backend's signed-upload flow.
  Future<List<String>> uploadPhotos(
    String productId,
    List<Uint8List> images,
  ) async {
    final user = _auth.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final urls = <String>[];
    final ts = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < images.length; i++) {
      final path = '${user.id}/$productId/${ts}_$i.jpg';
      final signedRes = await _api.post('/storage/signed-upload',
          body: {'bucket': _bucket, 'path': path}, requireAuth: true);
      final m = signedRes is Map ? Map<String, dynamic>.from(signedRes) : <String, dynamic>{};
      final signedUrl = m['signedUrl'] as String;
      final publicUrl = m['publicUrl'] as String;

      final put = await http.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': 'image/jpeg', 'x-upsert': 'true'},
        body: images[i],
      );
      if (put.statusCode < 200 || put.statusCode >= 300) {
        throw Exception('Photo upload failed: ${put.statusCode}');
      }
      urls.add(publicUrl);
    }
    return urls;
  }

  Future<List<MyReviewItem>> getMyReviews() async {
    if (_auth.auth.currentUser == null) return const [];

    final data = await _api.get('/reviews/my', requireAuth: true,
        queryParams: {'limit': '500'});
    final list = (data is Map && data['reviews'] is List)
        ? data['reviews'] as List
        : const [];
    return list.whereType<Map>().map((j) {
      final m = Map<String, dynamic>.from(j);
      final p = (m['product'] is Map)
          ? Map<String, dynamic>.from(m['product'] as Map)
          : (m['products'] is Map ? Map<String, dynamic>.from(m['products'] as Map) : null);
      final imgs = (p?['image_urls'] as List?)?.cast<String>() ?? const [];
      return MyReviewItem(
        review: _toReview(m, defaultUserName: 'You'),
        productName: p?['name'] as String? ?? 'Product',
        productImageUrl: imgs.isNotEmpty ? imgs.first : null,
        status: m['status'] as String? ?? 'approved',
      );
    }).toList();
  }

  RatingSummary _summarize(List<Review> reviews) {
    if (reviews.isEmpty) {
      return RatingSummary(
        averageRating: 0,
        totalReviews: 0,
        starCounts: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    }
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var total = 0.0;
    for (final r in reviews) {
      final s = r.rating.round().clamp(1, 5);
      counts[s] = (counts[s] ?? 0) + 1;
      total += r.rating;
    }
    return RatingSummary(
      averageRating: total / reviews.length,
      totalReviews: reviews.length,
      starCounts: counts,
    );
  }
}

class MyReviewItem {
  final Review review;
  final String productName;
  final String? productImageUrl;
  final String status;

  MyReviewItem({
    required this.review,
    required this.productName,
    required this.productImageUrl,
    required this.status,
  });
}

class ReviewNotEligibleException implements Exception {
  const ReviewNotEligibleException();
  @override
  String toString() =>
      'You can review this product only after your order is delivered.';
}
