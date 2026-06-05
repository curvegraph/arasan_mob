import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/review.dart';
import '../data/services/review_service.dart';
export '../data/services/review_service.dart' show MyReviewItem, ReviewNotEligibleException;

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();
  final SupabaseClient _client = Supabase.instance.client;

  final List<Review> _reviews = [];
  final Map<String, RatingSummary> _ratingSummaries = {};
  final Set<String> _myHelpfulVotes = {};
  List<MyReviewItem> _myReviews = [];

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MyReviewItem> get myReviews => _myReviews;

  List<Review> getProductReviews(String productId) {
    return _reviews.where((r) => r.productId == productId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  RatingSummary? getRatingSummary(String productId) =>
      _ratingSummaries[productId];

  double getAverageRating(String productId) =>
      _ratingSummaries[productId]?.averageRating ?? 0;

  int getReviewCount(String productId) =>
      _ratingSummaries[productId]?.totalReviews ?? 0;

  bool didMarkHelpful(String reviewId) => _myHelpfulVotes.contains(reviewId);

  Review? getUserReview(String productId) {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return _reviews.firstWhere(
        (r) => r.productId == productId && r.userId == user.id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getProductReviews(productId);
      _reviews
        ..removeWhere((r) => r.productId == productId)
        ..addAll(result.reviews);
      _ratingSummaries[productId] = result.summary;

      final votes =
          await _service.getMyHelpfulVotes(result.reviews.map((r) => r.id).toList());
      _myHelpfulVotes
        ..removeWhere(
            (id) => result.reviews.any((r) => r.id == id) && !votes.contains(id))
        ..addAll(votes);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addReview({
    required String productId,
    required double rating,
    required String comment,
    String? title,
    List<Uint8List> photoBytes = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _error = 'Please sign in to submit a review';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<String> photoUrls = const [];
      if (photoBytes.isNotEmpty) {
        photoUrls = await _service.uploadPhotos(productId, photoBytes);
      }
      await _service.addReview(
        productId: productId,
        rating: rating.round(),
        review: comment,
        title: title,
        photos: photoUrls,
      );
      await loadProductReviews(productId);
      return true;
    } catch (e) {
      final msg = e.toString();
      if (e is ReviewNotEligibleException) {
        _error = 'You can review this product only after your order is delivered.';
      } else if (msg.contains('duplicate key') || msg.contains('unique')) {
        _error = 'You have already reviewed this product';
      } else {
        _error = 'Failed to submit review';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    String? title,
    List<String>? keepPhotos,
    List<Uint8List> newPhotoBytes = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _error = 'Please sign in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final review = _findReview(reviewId);
      List<String>? photos;
      if (keepPhotos != null || newPhotoBytes.isNotEmpty) {
        photos = [...?keepPhotos];
        if (newPhotoBytes.isNotEmpty) {
          final urls = await _service.uploadPhotos(
              review?.productId ?? '', newPhotoBytes);
          photos.addAll(urls);
        }
      }
      await _service.updateReview(
        reviewId: reviewId,
        rating: rating.round(),
        review: comment,
        title: title,
        photos: photos,
      );
      if (review != null) {
        await loadProductReviews(review.productId);
      }
      await loadMyReviews();
      return true;
    } catch (_) {
      _error = 'Failed to update review';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      final review = _findReview(reviewId);
      await _service.deleteReview(reviewId);
      _reviews.removeWhere((r) => r.id == reviewId);
      if (review != null) {
        await loadProductReviews(review.productId);
      }
      await loadMyReviews();
      return true;
    } catch (_) {
      _error = 'Failed to delete review';
      notifyListeners();
      return false;
    }
  }

  Future<void> markHelpful(String reviewId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final wasMarked = _myHelpfulVotes.contains(reviewId);
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;

    _reviews[index] = _reviews[index].copyWith(
      helpfulCount: (_reviews[index].helpfulCount + (wasMarked ? -1 : 1))
          .clamp(0, 1 << 31),
    );
    if (wasMarked) {
      _myHelpfulVotes.remove(reviewId);
    } else {
      _myHelpfulVotes.add(reviewId);
    }
    notifyListeners();

    try {
      final isHelpful = await _service.toggleHelpful(reviewId);
      if (isHelpful != !wasMarked) {
        if (isHelpful) {
          _myHelpfulVotes.add(reviewId);
        } else {
          _myHelpfulVotes.remove(reviewId);
        }
        notifyListeners();
      }
    } catch (_) {
      _reviews[index] = _reviews[index].copyWith(
        helpfulCount: (_reviews[index].helpfulCount + (wasMarked ? 1 : -1))
            .clamp(0, 1 << 31),
      );
      if (wasMarked) {
        _myHelpfulVotes.add(reviewId);
      } else {
        _myHelpfulVotes.remove(reviewId);
      }
      notifyListeners();
    }
  }

  /// Returns: ('eligible', null) if the user can submit a new review,
  /// ('already_reviewed', reviewId) if they already wrote one,
  /// ('not_purchased', null) if they have no delivered order,
  /// ('not_signed_in', null) if no auth.
  Future<({String status, String? existingReviewId})> reviewEligibility(
      String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) return (status: 'not_signed_in', existingReviewId: null);

    final existing = await _service.getMyReviewForProduct(productId);
    if (existing != null) {
      return (status: 'already_reviewed', existingReviewId: existing.id);
    }
    final delivered = await _service.hasDeliveredPurchase(productId);
    return (
      status: delivered ? 'eligible' : 'not_purchased',
      existingReviewId: null,
    );
  }

  Future<bool> canReview(String productId) async {
    final res = await reviewEligibility(productId);
    return res.status == 'eligible';
  }

  Future<void> loadMyReviews() async {
    try {
      _myReviews = await _service.getMyReviews();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Review? _findReview(String reviewId) {
    try {
      return _reviews.firstWhere((r) => r.id == reviewId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
