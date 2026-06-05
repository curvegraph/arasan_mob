import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/user_activity_provider.dart';

/// "Recommended for You" section — personalized product suggestions.
///
/// Shows products based on:
/// - Wishlist items (same brand/category)
/// - Recently viewed (same brand/category/price range)
/// - Search history (matching terms)
/// - Falls back to top-rated products, then placeholders.
class RecommendedSection extends StatelessWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final activityProvider = context.watch<UserActivityProvider>();
    final productProvider = context.watch<ProductProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();

    final recommendations = activityProvider.getRecommendations(
      allProducts: productProvider.allProducts,
      wishlistProductIds: wishlistProvider.items.map((i) => i.productId).toList(),
      limit: 15,
    );
    final searchHistory = activityProvider.searchHistory;
    final hasRecommendations = recommendations.isNotEmpty;

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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended for You',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Based on your interests',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/shop/products'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Horizontal scrollable product cards ──
          SizedBox(
            height: 270,
            child: hasRecommendations
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recommendations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _RecommendedProductCard(
                        product: recommendations[index],
                        index: index,
                      );
                    },
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _RecommendedPlaceholderCard(index: index);
                    },
                  ),
          ),

          const SizedBox(height: 12),

          // ── "Still looking for?" tag chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still looking for?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: searchHistory.isNotEmpty
                      ? searchHistory
                          .take(5)
                          .map((q) => _SearchTagChip(
                                label: q,
                                onTap: () => context.push('/shop/search?q=$q'),
                              ))
                          .toList()
                      : const [
                          _SearchTagChip(label: 'Samsung Galaxy'),
                          _SearchTagChip(label: 'iPhone'),
                          _SearchTagChip(label: 'Under ₹15,000'),
                          _SearchTagChip(label: '5G Phones'),
                          _SearchTagChip(label: 'Best Camera'),
                        ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vibrant product card — Flipkart/Meesho inspired with bold colors,
/// gradient image backgrounds, price banner strip, and hover lift effect.
class _RecommendedProductCard extends StatefulWidget {
  final Product product;
  final int index;
  const _RecommendedProductCard({required this.product, required this.index});

  @override
  State<_RecommendedProductCard> createState() => _RecommendedProductCardState();
}

class _RecommendedProductCardState extends State<_RecommendedProductCard> {
  bool _hovering = false;

  // Bold gradient pairs for image backgrounds
  static const _gradients = [
    [Color(0xFF1A1A2E), Color(0xFF16213E)], // dark navy
    [Color(0xFF0F2027), Color(0xFF2C5364)], // deep teal
    [Color(0xFF232526), Color(0xFF414345)], // charcoal
    [Color(0xFF1D1D3B), Color(0xFF3B1D5E)], // dark purple
    [Color(0xFF0D1B2A), Color(0xFF1B3A4B)], // midnight blue
    [Color(0xFF2D1B69), Color(0xFF11998E)], // purple-teal
  ];

  // Price strip colors
  static const _stripColors = [
    Color(0xFFC6FF00), // lime
    Color(0xFF00E676), // green
    Color(0xFFFFD600), // yellow
    Color(0xFF00E5FF), // cyan
    Color(0xFFFF9100), // orange
    Color(0xFF76FF03), // light green
  ];

  @override
  Widget build(BuildContext context) {
    final grad = _gradients[widget.index % _gradients.length];
    final stripColor = _stripColors[widget.index % _stripColors.length];
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => context.push('/shop/product/${product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 170,
          transform: Matrix4.translationValues(0, _hovering ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? Colors.black.withValues(alpha:0.18)
                    : Colors.black.withValues(alpha:0.08),
                blurRadius: _hovering ? 20 : 10,
                offset: Offset(0, _hovering ? 10 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // ── Image area with gradient bg ──
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: grad,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Product image — fills the area
                        Positioned.fill(
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.phone_android,
                                      size: 50,
                                      color: Colors.white38,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.phone_android,
                                    size: 50,
                                    color: Colors.white38,
                                  ),
                                ),
                        ),

                        // Brand badge top-left
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.brand.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),

                        // Discount badge top-right
                        if (product.hasDiscount)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3D00),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.discountPercent.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Price strip banner ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  color: stripColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.effectivePrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                            color: const Color(0xFF1A1A1A).withValues(alpha:0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Product name + tagline ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.hasDiscount ? 'Great Deal' : 'Best Seller',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder card — matching the vibrant style with shimmer-like placeholders.
class _RecommendedPlaceholderCard extends StatelessWidget {
  final int index;
  const _RecommendedPlaceholderCard({required this.index});

  static const _gradients = [
    [Color(0xFF1A1A2E), Color(0xFF16213E)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF232526), Color(0xFF414345)],
    [Color(0xFF1D1D3B), Color(0xFF3B1D5E)],
    [Color(0xFF0D1B2A), Color(0xFF1B3A4B)],
    [Color(0xFF2D1B69), Color(0xFF11998E)],
  ];

  static const _stripColors = [
    Color(0xFFC6FF00),
    Color(0xFF00E676),
    Color(0xFFFFD600),
    Color(0xFF00E5FF),
    Color(0xFFFF9100),
    Color(0xFF76FF03),
  ];

  @override
  Widget build(BuildContext context) {
    final grad = _gradients[index % _gradients.length];
    final stripColor = _stripColors[index % _stripColors.length];

    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Image area
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: grad,
                  ),
                ),
                child: const Center(
                  child:
                      Icon(Icons.phone_android, size: 50, color: Colors.white24),
                ),
              ),
            ),
            // Price strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              color: stripColor.withValues(alpha:0.5),
              child: Center(
                child: Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search tag chip — shows user's recent searches or default suggestions.
class _SearchTagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SearchTagChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
