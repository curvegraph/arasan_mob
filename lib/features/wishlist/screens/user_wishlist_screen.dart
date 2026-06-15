import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_animations.dart';
import '../../../core/utils/glass_morphism.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/shared_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../shared/widgets/product_card_mini.dart';

class UserWishlistScreen extends StatefulWidget {
  const UserWishlistScreen({super.key});

  @override
  State<UserWishlistScreen> createState() => _UserWishlistScreenState();
}

class _UserWishlistScreenState extends State<UserWishlistScreen> {
  // 0 = Wishlist, 1 = Shared
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final sharedProvider = context.watch<SharedProvider>();
    final wishlistCount = wishlistProvider.items.length;
    final sharedCount = sharedProvider.count;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: const Text(
          'My Lists',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
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
      body: Column(
        children: [
          _buildTabBar(wishlistCount, sharedCount),
          Expanded(
            child: _tab == 0
                ? _buildWishlistTab(auth, wishlistProvider)
                : _buildSharedTab(sharedProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int wishlistCount, int sharedCount) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _tabPill(
            label: 'Wishlist',
            count: wishlistCount,
            icon: Icons.favorite_outline,
            selected: _tab == 0,
            onTap: () => setState(() => _tab = 0),
          ),
          const SizedBox(width: 10),
          _tabPill(
            label: 'Shared',
            count: sharedCount,
            icon: Icons.ios_share_outlined,
            selected: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
        ],
      ),
    );
  }

  Widget _tabPill({
    required String label,
    required int count,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WISHLIST TAB ──────────────────────────────────────────────────────────
  Widget _buildWishlistTab(
      AuthProvider auth, WishlistProvider wishlistProvider) {
    if (!auth.isLoggedIn) {
      return _loginPrompt();
    }
    if (wishlistProvider.items.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_border,
        title: 'Your Wishlist is Empty',
        subtitle: 'Save items you love for later',
      );
    }
    return _buildGrid(wishlistProvider);
  }

  // ── SHARED TAB ────────────────────────────────────────────────────────────
  Widget _buildSharedTab(SharedProvider sharedProvider) {
    final ids = sharedProvider.productIds;
    if (ids.isEmpty) {
      return _emptyState(
        icon: Icons.ios_share_outlined,
        title: 'Nothing Shared Yet',
        subtitle:
            'Products you share with friends\nshow up here as suggestions',
      );
    }
    return _buildSharedGrid(sharedProvider);
  }

  Widget _loginPrompt() {
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
                child: const Icon(Icons.favorite_border,
                    size: 44, color: AppColors.wishlistRed),
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
                  child: const Text('Login',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                child: Icon(icon, size: 44, color: AppColors.wishlistRed),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                  label: const Text('Start Shopping',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  int _crossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _aspectFor(int crossAxisCount) => crossAxisCount >= 4
      ? 0.66
      : crossAxisCount == 3
          ? 0.64
          : 0.62;

  /// Wishlist grid — the SAME product tiles used across the storefront.
  Widget _buildGrid(WishlistProvider wishlistProvider) {
    final items = wishlistProvider.items;
    final productProvider = context.watch<ProductProvider>();
    final width = MediaQuery.sizeOf(context).width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in items) {
        if (productProvider.getProductById(item.productId) == null) {
          productProvider.fetchProductById(item.productId);
        }
      }
    });

    final crossAxisCount = _crossAxisCount(width);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: _aspectFor(crossAxisCount),
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
        return FadeSlideIn(index: index, child: ProductCardMini(product: product));
      },
    );
  }

  /// Shared grid — products the user shared. Same tiles as the wishlist, with a
  /// small "remove" badge to drop an item from the Shared list.
  Widget _buildSharedGrid(SharedProvider sharedProvider) {
    final ids = sharedProvider.productIds;
    final productProvider = context.watch<ProductProvider>();
    final width = MediaQuery.sizeOf(context).width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final id in ids) {
        if (productProvider.getProductById(id) == null) {
          productProvider.fetchProductById(id);
        }
      }
    });

    final crossAxisCount = _crossAxisCount(width);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: _aspectFor(crossAxisCount),
      ),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final id = ids[index];
        final product = productProvider.getProductById(id);
        if (product == null) {
          return FadeSlideIn(
            index: index,
            child: _UnavailableCard(
              onRemove: () => sharedProvider.remove(id),
            ),
          );
        }
        return FadeSlideIn(
          index: index,
          child: Stack(
            children: [
              ProductCardMini(product: product),
              // Un-share badge (top-left, so it doesn't collide with the
              // wishlist heart at top-right of the card).
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: () => sharedProvider.remove(id),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassWhite),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
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
                  Icon(Icons.error_outline, size: 40, color: AppColors.textHint),
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
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
