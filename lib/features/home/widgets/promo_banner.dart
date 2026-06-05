import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/responsive_helper.dart';

/// Promotional banner - "Get 5% Cash Back on Arasan Mobiles" style.
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.xl : AppSpacing.xxl),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arasan Mobiles',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () => context.push('/shop/products'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Text(
                      'Shop Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: isMobile ? 80 : 120,
                height: isMobile ? 80 : 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.percent,
                  size: isMobile ? 36 : 52,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
