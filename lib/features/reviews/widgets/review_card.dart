import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/review.dart';
import '../../../shared/widgets/rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onHelpful;
  final bool didMarkHelpful;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
    this.didMarkHelpful = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = review.userName.isNotEmpty
        ? review.userName[0].toUpperCase()
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.darkCard(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.userPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.userPrimary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.userPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 10,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.format(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Rating stars
          RatingStars(rating: review.rating, size: 16),
          const SizedBox(height: AppSpacing.sm),

          // Comment
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),

          // Photos
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.glassWhite),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        review.photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image,
                          color: AppColors.textHint,
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Helpful button
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: AppColors.glassWhite),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              InkWell(
                onTap: onHelpful,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        didMarkHelpful
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 16,
                        color: didMarkHelpful
                            ? AppColors.userPrimary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Helpful${review.helpfulCount > 0 ? ' (${review.helpfulCount})' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: didMarkHelpful
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: didMarkHelpful
                              ? AppColors.userPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
