import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../shared/widgets/product_card_mini.dart';

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

  /// Wishlist as the SAME product grid used across the storefront —
  /// `ProductCardMini` tiles (hero image, discount tag, brand/rating, price,
  /// wishlist heart + Add/Buy CTAs). Tapping the filled heart removes the item.
  Widget _buildGrid(BuildContext context, WishlistProvider wishlistProvider) {
    final items = wishlistProvider.items;
    final productProvider = context.watch<ProductProvider>();
    final width = MediaQuery.sizeOf(context).width;

    // Any wishlist row whose product isn't cached yet gets fetched in the
    // background; the grid rebuilds as products arrive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in items) {
        if (productProvider.getProductById(item.productId) == null) {
          productProvider.fetchProductById(item.productId);
        }
      }
    });

    int crossAxisCount = 2;
    if (width >= 1200) {
      crossAxisCount = 5;
    } else if (width >= 900) {
      crossAxisCount = 4;
    } else if (width >= 600) {
      crossAxisCount = 3;
    }
    final aspect = crossAxisCount >= 4
        ? 0.66
        : crossAxisCount == 3
            ? 0.64
            : 0.62;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: aspect,
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
          child: ProductCardMini(product: product),
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
