import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card_mini.dart';

/// Adaptive product grid -- 2 columns mobile, 3 tablet, 4 desktop.
/// Uses [ProductCardMini] for each item with generous 20px spacing.
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ProductGrid({
    super.key,
    required this.products,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.responsive<int>(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 5,
    );

    final childAspectRatio = ResponsiveHelper.responsive<double>(
      context,
      mobile: 0.58,
      tablet: 0.56,
      desktop: 0.58,
    );

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textHint.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No products found',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Try adjusting your filters or search query',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.userPagePadding,
            vertical: AppSpacing.sm,
          ),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCardMini(
          product: products[index],
          staggerIndex: index,
        );
      },
    );
  }
}
