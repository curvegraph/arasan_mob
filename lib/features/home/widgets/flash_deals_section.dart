import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/product_card_mini.dart';

/// "Today's Best Deals For You!" section with a grid of product cards.
class FlashDealsSection extends StatelessWidget {
  const FlashDealsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().allProducts;
    final isMobile = ResponsiveHelper.isMobile(context);
    final crossAxisCount = isMobile ? 2 : 4;

    // Take up to 8 products for the deals section
    final dealProducts = products.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Todays Best Deals For You!",
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.md),

        if (dealProducts.isEmpty)
          _buildEmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = AppSpacing.md;
              final cardWidth =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;
              final cardHeight = cardWidth * 1.55;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: dealProducts.map((product) {
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: ProductCardMini(
                      product: product,
                      width: cardWidth,
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Check back for amazing deals!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'New offers are added regularly',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
