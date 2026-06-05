import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';

/// "Trending Products For You!" section with large category/store cards.
class TrendingStores extends StatelessWidget {
  const TrendingStores({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Products For You!',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        if (isMobile)
          Column(
            children: [
              _TrendingCard(
                title: 'Latest Smartphones',
                subtitle: '',
                icon: Icons.phone_android,
                bgColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: AppSpacing.md),
              _TrendingCard(
                title: 'Premium Accessories',
                subtitle: '',
                icon: Icons.headphones,
                bgColor: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1565C0),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _TrendingCard(
                  title: 'Latest Smartphones',
                  subtitle: '',
                  icon: Icons.phone_android,
                  bgColor: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TrendingCard(
                  title: 'Premium Accessories',
                  subtitle: '',
                  icon: Icons.headphones,
                  bgColor: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _TrendingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/products'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large icon area
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                size: 56,
                color: iconColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Shop Now button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Text(
                'Shop Now',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
