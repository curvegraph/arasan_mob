import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../shared/widgets/auth_gate.dart';
import '../../../shared/widgets/delivery_badge.dart';
import '../../../shared/widgets/tax_label.dart';
import '../../../shared/widgets/trust_badges_row.dart';
import '../../auth/screens/login_dialog.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  int _qty = 1;
  int _selectedImageIndex = 0;
  ProductVariant? _selectedVariant;
  late AnimationController _animationController;

  // Display values that follow the currently selected variant (or the base
  // product when none is selected).
  List<String> _dispImages(Product p) {
    final v = _selectedVariant;
    if (v != null && v.imageUrls.isNotEmpty) return v.imageUrls;
    return p.imageUrls;
  }

  double _dispPrice(Product p) => _selectedVariant?.price ?? p.price;
  double _dispEffectivePrice(Product p) =>
      _selectedVariant?.effectivePrice ?? p.effectivePrice;
  int _dispDiscount(Product p) =>
      (_selectedVariant?.discountPercent ?? p.discountPercent).toInt();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      // Always fetch full product (listing cache doesn't include specs/description)
      provider.fetchProductById(widget.productId);
      // Re-fetch settings so admin trust-badge / delivery / tax edits show up
      // immediately instead of after the 60s background poll.
      context.read<StoreSettingsProvider>().loadSettings(force: true);
      context.read<UserActivityProvider>().addRecentlyViewed(widget.productId);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final product = productProvider.getProductById(widget.productId);
    if (product == null) {
      // Show loading if products are still being fetched
      if (productProvider.isLoading || productProvider.allProducts.isEmpty) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      }
      return _notFound();
    }

    final wishlist = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final isWishlisted = wishlist.isInWishlist(product.id);
    final isInCart = cart.isInCart(product.id);
    final avgRating = reviewProvider.getAverageRating(product.id);
    final reviewCount = reviewProvider.getReviewCount(product.id);
    final images = product.imageUrls.isNotEmpty ? product.imageUrls : <String>[];
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 768;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: isDesktop
          ? _buildDesktopLayout(product, images, isWishlisted, isInCart, avgRating, reviewCount, wishlist, cart, width)
          : _buildMobileLayout(product, images, isWishlisted, isInCart, avgRating, reviewCount, wishlist, cart),
      bottomNavigationBar: isDesktop
          ? null
          : _buildMobileBottomBar(product, isInCart, cart),
    );
  }

  // ===========================================================================
  // ACTION ROW (Wishlist, Share) — no duplicate back button
  // ===========================================================================
  Widget _buildActionRow(bool isWishlisted, WishlistProvider wishlist, Product product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Spacer(),
          // Wishlist button
          IconButton(
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: isWishlisted ? AppColors.wishlistRed : AppColors.textSecondary,
              size: 24,
            ),
            onPressed: () => requireAuth(context, action: () async {
              await wishlist.toggleWishlist(product.id);
            }),
          ),
          // Share button — copies OG URL to clipboard
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22, color: AppColors.textSecondary),
            onPressed: () {
              final shareUrl = 'https://arasanmobiles.com/shop/product/${product.id}';
              Clipboard.setData(ClipboardData(text: shareUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product link copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT (stacked)
  // ===========================================================================
  Widget _buildMobileLayout(
    Product product, List<String> images, bool isWishlisted, bool isInCart,
    double avgRating, int reviewCount, WishlistProvider wishlist, CartProvider cart,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel — wishlist + share are overlaid on the image
          // (top-right corner), with the discount badge top-left.
          _buildImageCarousel(images, product),

          // Product info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandAndStock(product),
                const SizedBox(height: 8),
                _buildProductName(product),
                const SizedBox(height: 8),
                _buildRatingRow(avgRating, reviewCount, product),
                if (product.variants.length >= 2) ...[
                  const SizedBox(height: 16),
                  _buildVariantSelector(product),
                ],
                const SizedBox(height: 12),
                _buildPriceRow(product),
                const SizedBox(height: 4),
                const TaxLabel(fontSize: 12),
                const SizedBox(height: 6),
                const DeliveryBadge(
                  fontSize: 13,
                  iconSize: 16,
                ),
                const SizedBox(height: 16),
                TrustBadgesRow(product: product),
                const SizedBox(height: 16),
                _buildQuantitySelector(),
                const SizedBox(height: 16),
                if (product.description.isNotEmpty) _buildDescription(product),
                if (product.specs.isNotEmpty) _buildHighlights(product),
                if (product.specs.isNotEmpty) _buildSpecifications(product),
                _buildReviewsSection(avgRating, reviewCount, product),
                const SizedBox(height: 16),
                _buildSimilarProducts(context.watch<ProductProvider>(), product),
                const SizedBox(height: 80), // bottom bar clearance
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP LAYOUT (side-by-side)
  // ===========================================================================
  Widget _buildDesktopLayout(
    Product product, List<String> images, bool isWishlisted, bool isInCart,
    double avgRating, int reviewCount, WishlistProvider wishlist, CartProvider cart, double screenWidth,
  ) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Action icons row
                _buildActionRow(isWishlisted, wishlist, product),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT: Image Grid
                    Expanded(
                      flex: 5,
                      child: _buildImageGrid(images, product),
                    ),
                    const SizedBox(width: 32),
                    // RIGHT: Product Info
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBrandAndStock(product),
                          const SizedBox(height: 12),
                          _buildProductName(product),
                          const SizedBox(height: 8),
                          _buildRatingRow(avgRating, reviewCount, product),
                          const SizedBox(height: 16),
                          _buildPriceRow(product),
                          const SizedBox(height: 4),
                          const TaxLabel(fontSize: 13),
                          const SizedBox(height: 8),
                          const DeliveryBadge(
                            fontSize: 14,
                            iconSize: 18,
                          ),
                          const SizedBox(height: 16),
                          TrustBadgesRow(product: product),
                          const SizedBox(height: 24),
                          _buildDesktopActions(product, isInCart, cart),
                          const SizedBox(height: 16),
                          if (product.description.isNotEmpty) _buildDescription(product),
                          if (product.specs.isNotEmpty) _buildHighlights(product),
                          if (product.specs.isNotEmpty) _buildSpecifications(product),
                          _buildReviewsSection(avgRating, reviewCount, product),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSimilarProducts(context.watch<ProductProvider>(), product),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // IMAGE CAROUSEL (Mobile)
  // ===========================================================================
  Widget _buildImageCarousel(List<String> images, Product product) {
    // Follow the selected variant's images when one is chosen.
    images = _dispImages(product);
    final Widget content;
    if (images.isEmpty) {
      content = AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: AppColors.surfaceVariant,
          child: _buildProductImage(product.thumbnailUrl, animation: product.imageAnimation),
        ),
      );
    } else {
      content = _buildCarouselBody(images, product);
    }
    // Overlay the wishlist + share buttons (top-right) and discount badge
    // (top-left) directly on the image, matching the web product page.
    return Stack(
      children: [
        content,
        Positioned(top: 12, left: 12, child: _buildImageDiscountBadge(product)),
        Positioned(top: 12, right: 12, child: _buildImageActionButtons(product)),
      ],
    );
  }

  Widget _buildImageDiscountBadge(Product product) {
    final discount = _dispDiscount(product);
    if (discount <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1400E0), Color(0xFF2962FF)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$discount% OFF',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Stacked white circular buttons on the image: wishlist on top, share below.
  Widget _buildImageActionButtons(Product product) {
    final isWishlisted =
        context.watch<WishlistProvider>().isInWishlist(product.id);
    return Column(
      children: [
        _circleIconButton(
          icon: isWishlisted ? Icons.favorite : Icons.favorite_border,
          color: isWishlisted ? AppColors.wishlistRed : const Color(0xFF64748B),
          onTap: () => requireAuth(context, action: () async {
            await context.read<WishlistProvider>().toggleWishlist(product.id);
          }),
        ),
        const SizedBox(height: 10),
        _circleIconButton(
          icon: Icons.share_outlined,
          color: const Color(0xFF64748B),
          onTap: () {
            final shareUrl =
                'https://arasanmobiles.com/shop/product/${product.id}';
            Clipboard.setData(ClipboardData(text: shareUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product link copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildCarouselBody(List<String> images, Product product) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _selectedImageIndex = index);
              // Reset and replay animation when image changes
              _animationController.reset();
              _animationController.forward();
            },
            itemBuilder: (context, index) {
              return _ZoomableImage(
                child: Container(
                  color: AppColors.surfaceVariant,
                  padding: const EdgeInsets.all(24),
                  child: _buildProductImage(images[index], animation: product.imageAnimation),
                ),
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _selectedImageIndex == index ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _selectedImageIndex == index
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // IMAGE GRID (Desktop) — adaptive layout (1/2/3/4 images)
  // ===========================================================================
  Widget _buildImageGrid(List<String> images, Product product) {
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildProductImage(product.thumbnailUrl, animation: product.imageAnimation),
        ),
      );
    }

    final anim = product.imageAnimation;

    // Fixed total area — images expand to fill regardless of count
    return AspectRatio(
      aspectRatio: 1,
      child: _buildImageLayout(images, anim),
    );
  }

  Widget _buildImageLayout(List<String> images, ImageAnimation anim) {
    if (images.length == 1) {
      // Single image fills entire area
      return _imageTile(images[0], anim);
    } else if (images.length == 2) {
      // Side by side, each fills half width, full height
      return Row(
        children: [
          Expanded(child: _imageTile(images[0], anim)),
          const SizedBox(width: 6),
          Expanded(child: _imageTile(images[1], anim)),
        ],
      );
    } else if (images.length == 3) {
      // 1 large left (full height) + 2 stacked right
      return Row(
        children: [
          Expanded(child: _imageTile(images[0], anim)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _imageTile(images[1], anim)),
                const SizedBox(height: 6),
                Expanded(child: _imageTile(images[2], anim)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 2x2 grid
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _imageTile(images[0], anim)),
                const SizedBox(width: 6),
                Expanded(child: _imageTile(images[1], anim)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _imageTile(images[2], anim)),
                const SizedBox(width: 6),
                Expanded(child: _imageTile(images[3], anim)),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _imageTile(String url, ImageAnimation animation) {
    return _ZoomableImage(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.surfaceVariant,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => Center(
              child: Icon(Icons.phone_android, size: 48, color: AppColors.textHint),
            ),
            errorWidget: (_, __, ___) => Center(
              child: Icon(Icons.phone_android, size: 48, color: AppColors.textHint),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? url, {ImageAnimation animation = ImageAnimation.none}) {
    if (url == null || url.isEmpty) {
      return Center(
        child: Icon(Icons.phone_android, size: 48, color: AppColors.textHint),
      );
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Center(
        child: Icon(Icons.phone_android, size: 48, color: AppColors.textHint),
      ),
      errorWidget: (_, __, ___) => Center(
        child: Icon(Icons.phone_android, size: 48, color: AppColors.textHint),
      ),
    );

    // Apply animation based on type
    return _buildAnimatedImage(imageWidget, animation);
  }

  Widget _buildAnimatedImage(Widget child, ImageAnimation animation) {
    switch (animation) {
      case ImageAnimation.fadeIn:
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeIn,
          ),
          child: child,
        );
      case ImageAnimation.fadeOut:
        return FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.3).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
          ),
          child: child,
        );
      case ImageAnimation.zoomIn:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
          ),
          child: child,
        );
      case ImageAnimation.zoomOut:
        return ScaleTransition(
          scale: Tween<double>(begin: 1.2, end: 1.0).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
          ),
          child: child,
        );
      case ImageAnimation.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)),
          child: child,
        );
      case ImageAnimation.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)),
          child: child,
        );
      case ImageAnimation.bounce:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
          ),
          child: child,
        );
      case ImageAnimation.pulse:
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, animChild) {
            final scale = 1.0 + (0.05 * (1 - _animationController.value));
            return Transform.scale(scale: scale, child: animChild);
          },
          child: child,
        );
      case ImageAnimation.none:
        return child;
    }
  }

  // ===========================================================================
  // SHARED COMPONENTS
  // ===========================================================================

  Widget _buildBrandAndStock(Product product) {
    return Row(
      children: [
        Text(
          product.brand.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: product.isOutOfStock
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: product.isOutOfStock ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                product.isOutOfStock
                    ? 'Out of Stock'
                    : product.isLowStock
                        ? '${product.stock} left'
                        : 'In Stock',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: product.isOutOfStock ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductName(Product product) {
    return Text(
      product.name,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildRatingRow(double avgRating, int reviewCount, Product product) {
    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}/reviews'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.ratingBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  avgRating > 0 ? avgRating.toStringAsFixed(1) : product.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.star, size: 12, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$reviewCount reviews',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact horizontal variant picker (colour + storage/RAM). Tapping a box
  /// swaps the main image, price and discount in place.
  Widget _buildVariantSelector(Product product) {
    final variants = product.variants;
    if (variants.length < 2) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Variants',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 182,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: variants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final v = variants[i];
              final selected = _selectedVariant?.id == v.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedVariant = selected ? null : v;
                  _selectedImageIndex = 0;
                }),
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1400E0)
                          : const Color(0xFFE2E8F0),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.all(6),
                          child: v.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: v.imageUrl,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.phone_android,
                                      color: AppColors.textHint),
                                )
                              : const Icon(Icons.phone_android,
                                  color: AppColors.textHint),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (v.color != null && v.color!.isNotEmpty)
                              Text(
                                v.color!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            Text(
                              v.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(v.effectivePrice),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1400E0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(Product product) {
    final discount = _dispDiscount(product);
    final price = _dispPrice(product);
    final effectivePrice = _dispEffectivePrice(product);
    final savings = discount > 0 ? price - effectivePrice : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1400E0).withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                CurrencyFormatter.format(effectivePrice),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              if (discount > 0) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    CurrencyFormatter.format(price),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCBD5E1),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '$discount% off',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (savings > 0) ...[
            const SizedBox(height: 6),
            Text(
              '✓ You save ${CurrencyFormatter.format(savings)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Qty',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              _qtyBtn(Icons.remove, _qty > 1 ? () => setState(() => _qty--) : null),
              SizedBox(
                width: 40,
                height: 32,
                child: Center(
                  child: Text(
                    '$_qty',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              _qtyBtn(Icons.add, () => setState(() => _qty++)),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop: Add to cart + Buy now buttons inline (matches svelte design)
  Widget _buildDesktopActions(Product product, bool isInCart, CartProvider cart) {
    const brand = Color(0xFF1400E0);
    const brandDark = Color(0xFF0D00B3);

    return Column(
      children: [
        Row(children: [_buildQuantitySelector()]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: product.isOutOfStock
                      ? null
                      : () {
                          if (isInCart) {
                            context.push('/shop/cart');
                          } else {
                            final auth = context.read<AuthProvider>();
                            if (auth.isLoggedIn) {
                              for (int i = 0; i < _qty; i++) cart.addToCart(product);
                            } else {
                              LoginDialog.showWithMessage(
                                  context, 'Please login to add to cart');
                            }
                          }
                        },
                  icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                  label: Text(
                    product.isOutOfStock
                        ? 'Out of stock'
                        : isInCart
                            ? 'Go to cart'
                            : 'Add to Cart',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brand,
                    side: const BorderSide(color: brand, width: 2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: product.isOutOfStock
                      ? null
                      : () => requireAuth(
                            context,
                            message: 'Please login to buy',
                            action: () async {
                              for (int i = 0; i < _qty; i++) {
                                await cart.addToCart(product);
                              }
                              if (!context.mounted) return;
                              context.push('/shop/checkout');
                            },
                          ),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Buy Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    elevation: 4,
                    shadowColor: brandDark.withValues(alpha: 0.40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Mobile: Sticky bottom bar
  Widget _buildMobileBottomBar(Product product, bool isInCart, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(_dispEffectivePrice(product)),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (_dispDiscount(product) > 0)
                    Text(
                      '${_dispDiscount(product)}% off',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to Cart button
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: product.isOutOfStock
                      ? null
                      : () {
                          if (isInCart) {
                            context.push('/shop/cart');
                          } else {
                            final auth = context.read<AuthProvider>();
                            if (auth.isLoggedIn) {
                              for (int i = 0; i < _qty; i++) cart.addToCart(product);
                            } else {
                              LoginDialog.showWithMessage(context, 'Please login to add to cart');
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  child: Text(product.isOutOfStock ? 'OUT OF STOCK' : isInCart ? 'GO TO CART' : 'ADD TO CART'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(Product product) {
    return _expandableSection(
      'DESCRIPTION',
      Text(
        product.description,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildHighlights(Product product) {
    return _expandableSection(
      'HIGHLIGHTS',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: product.specs.entries.take(5).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(e.key, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSpecifications(Product product) {
    return _expandableSection(
      'SPECIFICATIONS',
      Column(
        children: product.specs.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(e.key, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildReviewsSection(double avgRating, int reviewCount, Product product) {
    return _expandableSection(
      'REVIEWS',
      GestureDetector(
        onTap: () => context.push('/shop/product/${product.id}/reviews'),
        child: Row(
          children: [
            ...List.generate(5, (i) => Icon(
              i < avgRating.round() ? Icons.star : Icons.star_border,
              size: 18, color: AppColors.rating,
            )),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${avgRating.toStringAsFixed(1)} out of 5  ($reviewCount reviews)',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const Text(
              'See all',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: onTap == null
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF1400E0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandableSection(String title, Widget content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        iconColor: AppColors.textTertiary,
        collapsedIconColor: AppColors.textTertiary,
        shape: const Border(bottom: BorderSide(color: AppColors.divider)),
        collapsedShape: const Border(bottom: BorderSide(color: AppColors.divider)),
        children: [content],
      ),
    );
  }

  // ===========================================================================
  // SIMILAR PRODUCTS
  // ===========================================================================
  Widget _buildSimilarProducts(ProductProvider provider, Product product) {
    final similar = provider.allProducts
        .where((p) => p.id != product.id && p.isActive && (p.brand == product.brand || p.category == product.category))
        .take(8).toList();

    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOU MAY ALSO LIKE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final item = similar[i];
              return GestureDetector(
                onTap: () => context.push('/shop/product/${item.id}'),
                child: SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProductImage(
                            item.thumbnailUrl ?? (item.imageUrls.isNotEmpty ? item.imageUrls.first : null),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(item.effectivePrice),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // NOT FOUND
  // ===========================================================================
  Widget _notFound() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'Product not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push('/shop/products'),
              child: const Text(
                'BROWSE PRODUCTS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hover-to-zoom widget: on mouse hover, zooms into the area where the cursor is
class _ZoomableImage extends StatefulWidget {
  final Widget child;

  const _ZoomableImage({required this.child});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  Offset _mousePosition = Offset.zero;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      cursor: _isHovering ? SystemMouseCursors.zoomIn : SystemMouseCursors.basic,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          if (!_isHovering || width == 0 || height == 0) {
            return widget.child;
          }

          // Calculate alignment based on mouse position (-1 to 1)
          final alignX = ((_mousePosition.dx / width) * 2 - 1).clamp(-1.0, 1.0);
          final alignY = ((_mousePosition.dy / height) * 2 - 1).clamp(-1.0, 1.0);

          return ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..translate(
                  -alignX * width * 0.3,
                  -alignY * height * 0.3,
                )
                ..scale(1.8),
              transformAlignment: Alignment.center,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
