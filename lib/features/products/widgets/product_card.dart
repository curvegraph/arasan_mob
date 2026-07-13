import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../shared/widgets/auth_gate.dart';
import '../../../shared/widgets/delivery_badge.dart';
import '../../../shared/widgets/image_placeholder.dart';
import '../../../shared/widgets/rating_stars.dart';

/// Vertical product card for 2-column grid display.
///
/// Flipkart/Meesho style: white card, image top, discount badge top-left,
/// wishlist heart top-right, brand, name, compact rating, price row with
/// MRP strikethrough and green discount %, free delivery tag.
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final isWishlisted = wishlist.isInWishlist(product.id);
    final averageRating = reviewProvider.getAverageRating(product.id);
    final reviewCount = reviewProvider.getReviewCount(product.id);

    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- IMAGE SECTION ----
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusCard),
                    ),
                    child: ImagePlaceholder(
                      imageUrl: product.thumbnailUrl ??
                          (product.imageUrls.isNotEmpty
                              ? product.imageUrls.first
                              : null),
                      height: 160,
                      width: double.infinity,
                      icon: Icons.phone_android,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Discount badge - top left
                  if (product.discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          '${product.discountPercent.toStringAsFixed(0)}% off',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist heart - top right
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => requireAuth(context, action: () async {
                        await wishlist.toggleWishlist(product.id);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isWishlisted
                              ? AppColors.wishlistRed
                              : AppColors.textHint,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Out of stock overlay
                  if (product.isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.radiusCard),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---- DETAILS SECTION ----
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Product name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Rating stars compact badge
                    RatingStars(
                      rating: averageRating,
                      size: 12,
                      showCount: true,
                      count: reviewCount,
                    ),
                    const SizedBox(height: 4),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Offer price
                        Text(
                          CurrencyFormatter.format(product.effectivePrice),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        // MRP strikethrough whenever a sale OR offer applies.
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              CurrencyFormatter.format(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.priceMRP,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          // "% off" only for a real admin offer.
                          if (product.discountPercent > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${product.discountPercent.toStringAsFixed(0)}% off',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.priceGreen,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Delivery info — driven by admin's store_settings.
                    const DeliveryBadge(
                      fontSize: 11,
                      iconSize: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
