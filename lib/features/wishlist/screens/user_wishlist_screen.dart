import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../data/models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../shared/widgets/image_placeholder.dart';

class UserWishlistScreen extends StatelessWidget {
  const UserWishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return _buildLoginPrompt(context);
    }

    final wishlistProvider = context.watch<WishlistProvider>();
    final items = wishlistProvider.items;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Wishlist',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${items.length} ${items.length == 1 ? 'item' : 'items'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      backgroundColor: AppColors.background,
      body: items.isEmpty
          ? _buildEmptyState(context)
          : _buildGrid(context, wishlistProvider),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.glassWhite,
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sectionSpacing),
          child: FadeSlideIn(
            index: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.wishlistRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.wishlistRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 44,
                    color: AppColors.wishlistRed,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Login to View Your Wishlist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Sign in to save and view your\nfavourite items.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.push('/shop/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.userPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionSpacing),
        child: FadeSlideIn(
          index: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.wishlistRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.wishlistRed.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 44,
                  color: AppColors.wishlistRed,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Your Wishlist is Empty',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Save items you love for later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: PremiumDecorations.goldGlowButton(),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/shop'),
                  icon: const Icon(Icons.explore_outlined, size: 20),
                  label: const Text(
                    'Start Shopping',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WishlistProvider wishlistProvider) {
    final items = wishlistProvider.items;
    final productProvider = context.watch<ProductProvider>();
    final width = MediaQuery.sizeOf(context).width;

    // Responsive grid columns
    int crossAxisCount = 2;
    if (width >= 1200) {
      crossAxisCount = 5;
    } else if (width >= 900) {
      crossAxisCount = 4;
    } else if (width >= 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.userPagePadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.66,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final wishlistItem = items[index];
        final product = productProvider.getProductById(wishlistItem.productId);

        if (product == null) {
          return FadeSlideIn(
            index: index,
            child: _UnavailableCard(
              onRemove: () =>
                  wishlistProvider.removeFromWishlist(wishlistItem.productId),
            ),
          );
        }

        return FadeSlideIn(
          index: index,
          child: _WishlistCard(
            product: product,
            onRemove: () =>
                wishlistProvider.removeFromWishlist(product.id),
          ),
        );
      },
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final VoidCallback onRemove;

  const _UnavailableCard({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PremiumDecorations.glassCard(),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Product Unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'This product is no longer available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassWhite),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;

  const _WishlistCard({
    required this.product,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.read<CartProvider>();

    return Container(
        decoration: PremiumDecorations.glassCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with remove button — tap to preview
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showImagePreview(context, product),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: ImagePlaceholder(
                      imageUrl: product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : null,
                      height: 140,
                      width: double.infinity,
                      icon: Icons.phone_android,
                    ),
                  ),
                ),
                if (product.discountPercent > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.offerBadge,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.offerBadge.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${product.discountPercent.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassWhite),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (product.isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product details — tap to go to detail page
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/shop/product/${product.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.userPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(product.effectivePrice),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.userPrimary,
                            ),
                          ),
                          if (product.offerPrice != null) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                CurrencyFormatter.format(product.price),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),

                    // Add to Cart & Buy Now buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton.icon(
                              onPressed: product.isOutOfStock
                                  ? null
                                  : () {
                                      cartProvider.addToCart(product);
                                    },
                              icon: const Icon(Icons.shopping_cart_outlined, size: 14),
                              label: const Text(
                                'Cart',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.addToCartGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.textHint.withValues(alpha: 0.3),
                                disabledForegroundColor: AppColors.textHint,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton.icon(
                              onPressed: product.isOutOfStock
                                  ? null
                                  : () {
                                      cartProvider.addToCart(product);
                                      context.push('/shop/checkout');
                                    },
                              icon: const Icon(Icons.flash_on, size: 14),
                              label: const Text(
                                'Buy Now',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.userPrimary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.textHint.withValues(alpha: 0.3),
                                disabledForegroundColor: AppColors.textHint,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _showImagePreview(BuildContext context, Product product) {
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.phone_android,
                              size: 80,
                              color: AppColors.textHint,
                            ),
                          )
                        : const Icon(
                            Icons.phone_android,
                            size: 80,
                            color: AppColors.textHint,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
