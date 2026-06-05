import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_helper.dart';

/// "Choose By Brand" section with brand cards showing logo, name, delivery info.
class ShopByBudget extends StatelessWidget {
  const ShopByBudget({super.key});

  static const List<_BrandData> _brands = [
    _BrandData(
      name: 'Samsung',
      icon: Icons.phone_android,
      color: Color(0xFF1565C0),
      bgColor: Color(0xFFE3F2FD),
    ),
    _BrandData(
      name: 'Apple',
      icon: Icons.apple,
      color: Color(0xFF424242),
      bgColor: Color(0xFFF5F5F5),
    ),
    _BrandData(
      name: 'OnePlus',
      icon: Icons.smartphone,
      color: Color(0xFFD32F2F),
      bgColor: Color(0xFFFFEBEE),
    ),
    _BrandData(
      name: 'Xiaomi',
      icon: Icons.devices,
      color: Color(0xFFFF6F00),
      bgColor: Color(0xFFFFF3E0),
    ),
    _BrandData(
      name: 'Vivo',
      icon: Icons.phone_iphone,
      color: Color(0xFF1565C0),
      bgColor: Color(0xFFE8EAF6),
    ),
    _BrandData(
      name: 'Oppo',
      icon: Icons.phonelink,
      color: Color(0xFF2E7D32),
      bgColor: Color(0xFFE8F5E9),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final crossAxisCount = isMobile ? 2 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose By Brand',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = AppSpacing.md;
            final cardWidth =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _brands.map((brand) {
                return SizedBox(
                  width: cardWidth,
                  child: _BrandCard(brand: brand),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BrandCard extends StatelessWidget {
  final _BrandData brand;

  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/products'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Brand icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: brand.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                brand.icon,
                size: 28,
                color: brand.color,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Brand name
            Text(
              brand.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandData {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _BrandData({
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
