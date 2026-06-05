class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final List<String> photos;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.photos = const [],
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Review copyWith({
    double? rating,
    String? comment,
    List<String>? photos,
    int? helpfulCount,
  }) {
    return Review(
      id: id,
      productId: productId,
      userId: userId,
      userName: userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      isVerifiedPurchase: isVerifiedPurchase,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt,
    );
  }
}

class RatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> starCounts;

  RatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.starCounts,
  });

  double getPercentage(int star) {
    if (totalReviews == 0) return 0;
    return (starCounts[star] ?? 0) / totalReviews * 100;
  }
}
