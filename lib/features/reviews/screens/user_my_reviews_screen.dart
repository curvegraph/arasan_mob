import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/services/review_service.dart';
import '../../../providers/review_provider.dart';
import '../../../shared/widgets/rating_stars.dart';

class UserMyReviewsScreen extends StatefulWidget {
  const UserMyReviewsScreen({super.key});

  @override
  State<UserMyReviewsScreen> createState() => _UserMyReviewsScreenState();
}

class _UserMyReviewsScreenState extends State<UserMyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadMyReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final items = provider.myReviews;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'My Reviews',
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
      body: provider.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () => provider.loadMyReviews(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.userPagePadding),
                    itemCount: items.length,
                    itemBuilder: (_, i) => FadeSlideIn(
                      index: i,
                      child: _MyReviewCard(
                        item: items[i],
                        onTapProduct: () => context.push(
                            '/shop/product/${items[i].review.productId}'),
                        onEdit: () => context.push(
                            '/shop/product/${items[i].review.productId}/write-review'),
                        onDelete: () => _confirmDelete(context, items[i]),
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MyReviewItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: Text('Your review of "${item.productName}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<ReviewProvider>().deleteReview(item.review.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Review deleted' : 'Failed to delete review'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  Widget _buildEmpty() {
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
            child: const Icon(Icons.rate_review_outlined,
                size: 48, color: AppColors.userPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            "You haven't written any reviews yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Reviews you write will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final MyReviewItem item;
  final VoidCallback onTapProduct;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyReviewCard({
    required this.item,
    required this.onTapProduct,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = item.review;
    final isHidden = item.status == 'hidden' || item.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: PremiumDecorations.darkCard(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTapProduct,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.surfaceVariant,
                    child: item.productImageUrl != null
                        ? Image.network(
                            item.productImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image,
                                color: AppColors.textHint),
                          )
                        : const Icon(Icons.phone_android,
                            color: AppColors.textHint),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingStars(rating: r.rating, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            DateFormatter.format(r.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isHidden) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_off,
                      size: 14, color: AppColors.warning),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This review was hidden by moderation',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              r.comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
          if (r.photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: r.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    r.photos[i],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.surfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.userPrimary,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
