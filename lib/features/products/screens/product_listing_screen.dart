import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/auth_gate.dart';
import '../../../shared/widgets/product_card_mini.dart';
import '../../../shared/widgets/product_placeholder_card.dart';
import '../../auth/screens/login_dialog.dart';
import '../widgets/filter_sidebar_panel.dart';
import '../widgets/product_filters_sheet.dart';
import '../widgets/sort_dropdown.dart';

/// Product listing screen with filter sidebar and vertical grid cards.
class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  SortOption _currentSort = SortOption.popularity;
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Schedule data loading for next frame to ensure UI renders first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initFromQueryParams();
      });
    }
  }

  void _initFromQueryParams() {
    if (!mounted) return;

    final uri = GoRouterState.of(context).uri;
    final category = uri.queryParameters['category'];
    final brand = uri.queryParameters['brand'];

    final provider = context.read<ProductProvider>();

    // Load data asynchronously - UI will show skeleton loaders while loading
    if (category != null && category.isNotEmpty) {
      provider.setFilterCategory(category);
    } else if (brand != null && brand.isNotEmpty) {
      provider.setFilterBrand(brand);
    } else {
      provider.initListing();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= 300) {
      final provider = context.read<ProductProvider>();
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadMoreProducts();
      }
    }
  }

  void _onSortChanged(SortOption sort) {
    setState(() => _currentSort = sort);

    final provider = context.read<ProductProvider>();
    switch (sort) {
      case SortOption.popularity:
        provider.changeSortOrder('display_order', true);
        break;
      case SortOption.newestFirst:
        provider.changeSortOrder('created_at', false);
        break;
      case SortOption.priceLowToHigh:
        provider.changeSortOrder('price', true);
        break;
      case SortOption.priceHighToLow:
        provider.changeSortOrder('price', false);
        break;
    }
  }

  String _getTitle(ProductProvider provider) {
    if (provider.filterCategory != null &&
        provider.filterCategory!.isNotEmpty) {
      return provider.filterCategory!;
    }
    if (provider.filterBrand != null && provider.filterBrand!.isNotEmpty) {
      return provider.filterBrand!;
    }
    return 'All Products';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.paginatedProducts;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 70,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTitle(provider),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${provider.paginatedProducts.length}${provider.hasMore ? '+' : ''} ${provider.paginatedProducts.length == 1 ? 'product' : 'products'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildSortFilterBar(isWideScreen, provider),
        ),
      ),
      body: isWideScreen
          ? _buildDesktopLayout(products, provider)
          : _buildMobileLayout(products, provider),
    );
  }

  /// Desktop/Tablet: sidebar + product grid
  Widget _buildDesktopLayout(List products, ProductProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSidebarPanel(),
        Expanded(
          child: _buildProductGrid(products, provider),
        ),
      ],
    );
  }

  /// Mobile: product grid only (filter via bottom sheet)
  Widget _buildMobileLayout(List products, ProductProvider provider) {
    return _buildProductGrid(products, provider);
  }

  Widget _buildSortFilterBar(bool isWideScreen, ProductProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (provider.paginatedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                '${provider.paginatedProducts.length}${provider.hasMore ? '+' : ''} results',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: SortDropdown(
              selectedSort: _currentSort,
              onSortChanged: _onSortChanged,
            ),
          ),
          if (!isWideScreen) ...[
            const SizedBox(width: AppSpacing.sm),
            _buildFilterButton(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterButton(ProductProvider provider) {
    final hasFilters = provider.hasActiveFilters;

    return GestureDetector(
      onTap: () {
        ProductFiltersSheet.show(context, provider: provider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasFilters
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: hasFilters ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color:
                  hasFilters ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Filter',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasFilters
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the product grid — no guest product limit, no guest scroll restriction
  Widget _buildProductGrid(List products, ProductProvider provider) {
    final category = provider.filterCategory;
    final showPlaceholders = provider.isLoading || products.isEmpty;
    final displayProducts = products;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const padding = 10.0;
        const spacing = 8.0;

        final crossAxisCount = availableWidth > 900
            ? 5
            : availableWidth > 600
                ? 4
                : 3;

        final itemWidth =
            (availableWidth - (padding * 2) - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;
        final itemHeight = itemWidth * 1.70;

        return CustomScrollView(
          controller: showPlaceholders ? null : _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Product grid or placeholder grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: spacing,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (showPlaceholders) {
                      return ProductPlaceholderCard(category: category);
                    }
                    return ProductCardMini(product: displayProducts[index]);
                  },
                  childCount: showPlaceholders
                      ? crossAxisCount * 3
                      : displayProducts.length,
                ),
              ),
            ),
            // Bottom indicator
            if (!showPlaceholders)
              SliverToBoxAdapter(
                child: _buildBottomIndicator(provider),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomIndicator(ProductProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
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
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: () => provider.loadMoreProducts(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Product card with colored image background, shadow, and gradient badges.
/// Image uses Expanded (no flex) with BoxFit.cover. Add to Cart & Buy Now buttons.
class _ProductGridCard extends StatelessWidget {
  final Product product;
  const _ProductGridCard({required this.product});

  // Soft pastel tints — each brand gets a consistent colour
  static const _imageBgColors = [
    Color(0xFFE8EAF6), // Indigo tint
    Color(0xFFE0F2F1), // Teal tint
    Color(0xFFFCE4EC), // Pink tint
    Color(0xFFF3E5F5), // Purple tint
    Color(0xFFE8F5E9), // Green tint
    Color(0xFFFFF3E0), // Orange tint
    Color(0xFFE1F5FE), // Light blue tint
    Color(0xFFFFF8E1), // Amber tint
  ];

  Color _getBrandBgColor() {
    final hash = product.brand.hashCode.abs();
    return _imageBgColors[hash % _imageBgColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBrandBgColor();

    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: bgColor.withValues(alpha:0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with coloured background — Expanded, no flex
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: bgColor,
                              child: Center(
                                child: Icon(
                                  getCategoryIcon(product.category),
                                  size: 44,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: bgColor,
                              child: Center(
                                child: Icon(
                                  getCategoryIcon(product.category),
                                  size: 44,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: bgColor,
                            child: Center(
                              child: Icon(
                                getCategoryIcon(product.category),
                                size: 44,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                  ),
                  // Wishlist heart
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer2<WishlistProvider, AuthProvider>(
                      builder: (context, wishlist, auth, _) {
                        final isWished = wishlist.isInWishlist(product.id);
                        return GestureDetector(
                          onTap: () => requireAuth(context, action: () async {
                            await wishlist.toggleWishlist(product.id);
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha:0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isWished ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: isWished ? AppColors.wishlistRed : AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          '${product.discountPercent.toInt()}% OFF',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details area — Padding with mainAxisSize.min
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand
                  Text(
                    product.brand,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Text(
                    CurrencyFormatter.format(product.effectivePrice),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Add to Cart & Buy Now
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      final isInCart = cart.isInCart(product.id);
                      return Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: product.isOutOfStock
                                    ? null
                                    : () {
                                        if (isInCart) {
                                          context.push('/shop/cart');
                                        } else {
                                          requireAuth(
                                            context,
                                            message: 'Please login to add to cart',
                                            action: () async {
                                              await cart.addToCart(product);
                                            },
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInCart
                                      ? AppColors.success
                                      : AppColors.primaryLight,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  product.isOutOfStock
                                      ? 'Out of Stock'
                                      : isInCart
                                          ? 'Go to Cart'
                                          : 'Add to Cart',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: product.isOutOfStock
                                    ? null
                                    : () => requireAuth(
                                          context,
                                          message: 'Please login to buy',
                                          action: () async {
                                            if (!isInCart) await cart.addToCart(product);
                                            if (!context.mounted) return;
                                            context.push('/shop/cart');
                                          },
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Buy Now',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
