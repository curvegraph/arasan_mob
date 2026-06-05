import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/user_activity_provider.dart';

/// Recently Viewed section — shows products the user has browsed.
/// Falls back to placeholder skeleton cards when no history exists.
class RecentlyViewedSection extends StatelessWidget {
  const RecentlyViewedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final activityProvider = context.watch<UserActivityProvider>();
    final productProvider = context.watch<ProductProvider>();

    final recentProducts =
        activityProvider.getRecentlyViewedProducts(productProvider.allProducts);
    final hasData = recentProducts.isNotEmpty;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
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
                      const Text(
                        'Recently Viewed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasData)
                  GestureDetector(
                    onTap: () {
                      activityProvider.clearRecentlyViewed();
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1400E0),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Cards ──
          SizedBox(
            height: 200,
            child: hasData
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _RecentProductCard(product: recentProducts[index]);
                    },
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return const _RecentlyViewedPlaceholder();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Real recently viewed product card.
class _RecentProductCard extends StatelessWidget {
  final Product product;
  const _RecentProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF8FAFC),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.phone_android, size: 36, color: Color(0xFFCBD5E1)),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.phone_android, size: 36, color: Color(0xFFCBD5E1)),
                        ),
                ),
              ),
            ),
            // Divider
            Container(height: 1, color: AppColors.border),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      CurrencyFormatter.format(product.effectivePrice),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
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

/// Placeholder card when no recently viewed history exists.
class _RecentlyViewedPlaceholder extends StatelessWidget {
  const _RecentlyViewedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Icon(Icons.phone_android, size: 36, color: Color(0xFFCBD5E1)),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: double.infinity, height: 9, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 5),
                _bar(width: 55, height: 9, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                _bar(width: 60, height: 11, color: const Color(0xFFE2E8F0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bar({required double height, required Color color, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }
}
