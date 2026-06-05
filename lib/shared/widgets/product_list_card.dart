import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product.dart';
import '../../providers/wishlist_provider.dart';
import 'auth_gate.dart';
import 'image_placeholder.dart';

/// Flipkart-style horizontal product card.
/// Image on the left (~120px), details on the right.
class ProductListCard extends StatelessWidget {
  final Product product;

  const ProductListCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.isInWishlist(product.id);

    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Product Image
            _buildImageSection(context, isWishlisted, wishlist),

            // Right: Product Details
            Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      Text(
                        product.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Rating badge
                      if (product.rating > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ratingBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.star,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${product.reviewCount})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.format(product.effectivePrice),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(product.price),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.priceMRP,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${product.discountPercent.toInt()}% off',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.discount,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Key specs
                      if (product.specs.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: product.specs.entries.take(3).map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
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

  Widget _buildImageSection(BuildContext context, bool isWishlisted, WishlistProvider wishlist) {
    return SizedBox(
      width: 120,
      child: Stack(
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppSpacing.radiusMd),
            ),
            child: ImagePlaceholder(
              imageUrl: product.thumbnailUrl ??
                  (product.imageUrls.isNotEmpty
                      ? product.imageUrls.first
                      : null),
              height: 160,
              width: 120,
              icon: Icons.phone_android,
              fit: BoxFit.cover,
            ),
          ),

          // Discount badge
          if (product.hasDiscount)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${product.discountPercent.toInt()}% OFF',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Wishlist heart
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => requireAuth(context, action: () async {
                await wishlist.toggleWishlist(product.id);
              }),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: isWishlisted
                      ? AppColors.wishlistRed
                      : AppColors.textHint,
                ),
              ),
            ),
          ),

          // Out of stock overlay
          if (product.isOutOfStock)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Out of\nStock',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
