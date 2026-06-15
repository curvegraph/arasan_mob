import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/review.dart';
import '../../../providers/review_provider.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../widgets/rating_bar.dart';
import '../widgets/review_card.dart';

class UserProductReviewsScreen extends StatefulWidget {
  final String productId;

  const UserProductReviewsScreen({super.key, required this.productId});

  @override
  State<UserProductReviewsScreen> createState() =>
      _UserProductReviewsScreenState();
}

class _UserProductReviewsScreenState extends State<UserProductReviewsScreen> {
  int? _selectedStarFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // View-only here — reviews are written from My Orders after delivery.
      context.read<ReviewProvider>().loadProductReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final ratingSummary = reviewProvider.getRatingSummary(widget.productId);
    final allReviews = reviewProvider.getProductReviews(widget.productId);

    final filteredReviews = _selectedStarFilter != null
        ? allReviews.where((r) => r.rating.round() == _selectedStarFilter).toList()
        : allReviews;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Customer Reviews',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Rating summary
          if (ratingSummary != null)
            SliverToBoxAdapter(
              child: FadeSlideIn(
                index: 0,
                child: _buildRatingSummary(ratingSummary),
              ),
            ),

          // Star filter chips
          SliverToBoxAdapter(
            child: FadeSlideIn(
              index: 1,
              child: _buildStarFilters(allReviews),
            ),
          ),

          // Reviews list
          if (filteredReviews.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyReviews(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.userPagePadding,
                0,
                AppSpacing.userPagePadding,
                AppSpacing.sectionSpacing,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final r = filteredReviews[index];
                    return FadeSlideIn(
                      index: index + 2,
                      child: ReviewCard(
                        review: r,
                        didMarkHelpful: reviewProvider.didMarkHelpful(r.id),
                        onHelpful: () => reviewProvider.markHelpful(r.id),
                      ),
                    );
                  },
                  childCount: filteredReviews.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(RatingSummary summary) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.userPagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.darkCard(borderRadius: 16),
      child: Row(
        children: [
          // Average rating
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: AppColors.userPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                RatingStars(rating: summary.averageRating, size: 20),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${summary.totalReviews} review${summary.totalReviews != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Star breakdown bars
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                return RatingBar(
                  starNumber: star,
                  percentage: summary.getPercentage(star),
                  count: summary.starCounts[star] ?? 0,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarFilters(List<Review> allReviews) {
    final filters = <int?>[null, 5, 4, 3, 2, 1];

    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.userPagePadding,
        ),
        child: Row(
          children: filters.map((star) {
            final isSelected = _selectedStarFilter == star;
            String label;
            if (star == null) {
              label = 'All';
            } else {
              final count =
                  allReviews.where((r) => r.rating.round() == star).length;
              label = '$star Star ($count)';
            }

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (star != null) ...[
                      Icon(
                        Icons.star,
                        size: 14,
                        color: isSelected ? Colors.white : AppColors.starYellow,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedStarFilter = star),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.userPrimary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.userPrimary : AppColors.glassWhite,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.userPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: AppColors.userPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _selectedStarFilter != null
                ? 'No $_selectedStarFilter-star reviews'
                : 'No Reviews Yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Reviews appear here once buyers receive their order',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
