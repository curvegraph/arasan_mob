import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card_mini.dart';

/// Horizontal scrollable product row with Shopcart-style cards.
class SectionProductRow extends StatelessWidget {
  final String? overline;
  final String headline;
  final List<Product> products;
  final String viewAllRoute;
  final IconData? titleIcon;
  final bool isDark;

  const SectionProductRow({
    super.key,
    this.overline,
    required this.headline,
    required this.products,
    required this.viewAllRoute,
    this.titleIcon,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        if (overline != null && overline!.isNotEmpty) ...[
          Text(
            overline!.toUpperCase(),
            style: AppTextStyles.overline.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1400E0), Color(0xFFA0D911)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 12),
            if (titleIcon != null) ...[
              Icon(titleIcon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                headline,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.push(viewAllRoute),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1400E0),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xFF1400E0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Product list or empty state
        if (products.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: 290,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 180,
                  child: ProductCardMini(
                    product: products[index],
                    width: 180,
                    staggerIndex: index,
                  ),
                );
              },
            ),
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
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No products available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Products will appear here once added',
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
