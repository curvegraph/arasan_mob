import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/auth_gate.dart';
import '../../../shared/widgets/product_placeholder_card.dart';

/// "All Products" section — tall rectangle card grid with real Supabase data,
/// sorting, and infinite scroll pagination. Shows placeholder skeleton cards
/// while loading or when no products exist.
class ProductsListSection extends StatefulWidget {
  const ProductsListSection({super.key});

  @override
  State<ProductsListSection> createState() => _ProductsListSectionState();
}

class _ProductsListSectionState extends State<ProductsListSection> {
  String _sortBy = 'popularity';

  @override
  void initState() {
    super.initState();
    // Products are loaded by the parent home screen's _loadData().
    // No need to trigger loadInitialProducts() here — it causes
    // redundant calls when this widget remounts due to section rebuilds.
  }

  void _onSortChanged(String? value) {
    if (value == null || value == _sortBy) return;
    setState(() => _sortBy = value);

    final provider = context.read<ProductProvider>();
    switch (value) {
      case 'popularity':
        provider.changeSortOrder('display_order', true);
        break;
      case 'newest':
        provider.changeSortOrder('created_at', false);
        break;
      case 'price_low':
        provider.changeSortOrder('price', true);
        break;
      case 'price_high':
        provider.changeSortOrder('price', false);
        break;
      case 'rating':
        provider.changeSortOrder('rating', false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.homeProducts;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive columns — more columns = smaller cards
    final crossAxisCount = screenWidth > 900
        ? 5
        : screenWidth > 600
            ? 4
            : 3;
    const horizontalPadding = 2.0;
    const spacing = 8.0;
    final itemWidth =
        (screenWidth - (horizontalPadding * 2) - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
    final itemHeight = itemWidth * 1.3;

    return Container(
      color: const Color(0xFFF0F4FF), // Very light blue tint
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with sort dropdown ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                        DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                        DropdownMenuItem(value: 'rating', child: Text('Rating')),
                      ],
                      onChanged: _onSortChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Product grid or placeholders ──
          if (products.isNotEmpty) ...[
            // Real product cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: products.map((product) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: _ProductCard(product: product),
                  );
                }).toList(),
              ),
            ),

            // Loading more spinner
            if (provider.homeIsLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ),


          ] else ...[
            // Placeholder grid (loading or empty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(crossAxisCount * 3, (index) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: const ProductPlaceholderCard(),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vibrant product card — Flipkart-inspired with bold image area,
/// colored price strip, hover lift, and compact layout.
class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovering = false;


  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => context.push('/shop/product/${product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? Colors.black.withValues(alpha:0.16)
                    : Colors.black.withValues(alpha:0.07),
                blurRadius: _hovering ? 18 : 8,
                offset: Offset(0, _hovering ? 8 : 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image area ──
                Expanded(
                  flex: 55,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                    ),
                    child: Stack(
                      children: [
                        // Product image
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
                                      size: 44,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.phone_android,
                                    size: 44,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                        ),
                        // Brand badge top-left
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha:0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              product.brand.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                        // Wishlist heart top-right
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Consumer2<WishlistProvider, AuthProvider>(
                            builder: (context, wishlist, auth, _) {
                              final isWished =
                                  wishlist.isInWishlist(product.id);
                              return GestureDetector(
                                onTap: () => requireAuth(context, action: () async {
                                  await wishlist.toggleWishlist(product.id);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha:0.08),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isWished
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 13,
                                    color: isWished
                                        ? Colors.red
                                        : const Color(0xFF666666),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Offer badge bottom-left — only for a real admin OFFER.
                        if (product.discountPercent > 0)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3D00),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product.discountPercent.toInt()}% OFF',
                                style: const TextStyle(
                                  fontSize: 8,
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

                // ── Price row ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(product.effectivePrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF212121),
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 4),
                        Text(
                          CurrencyFormatter.format(product.price),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[400],
                          ),
                        ),
                        if (product.discountPercent > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${product.discountPercent.toInt()}% off',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                // ── Compact details area ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Rating + Free delivery row
                      Row(
                        children: [
                          if (product.rating > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF388E3C),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 1),
                                  const Icon(Icons.star,
                                      size: 7, color: Colors.white),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          const Icon(Icons.local_shipping_outlined,
                              size: 10, color: Color(0xFF43A047)),
                          const SizedBox(width: 2),
                          Text(
                            'Free Delivery',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

