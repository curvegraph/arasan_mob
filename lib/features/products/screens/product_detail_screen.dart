import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../data/services/product_api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../providers/store_settings_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../shared/widgets/auth_gate.dart';
import '../../../shared/widgets/product_card_mini.dart';
import '../../../shared/widgets/delivery_badge.dart';
import '../../../shared/widgets/tax_label.dart';
import '../../../shared/widgets/trust_badges_row.dart';
import '../../auth/screens/login_dialog.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  /// Admin-curated variant to pre-select (e.g. the variant whose offer was
  /// shown on a Today's Offers / deal card). When null, the first variant is
  /// selected as before.
  final String? selectedVariantId;
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.selectedVariantId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  int _qty = 1;
  int _selectedImageIndex = 0;
  ProductVariant? _selectedVariant;
  String? _selectedColor;
  bool _variantInitialized = false;
  bool _detailLoading = true;
  List<Product> _related = const [];
  late AnimationController _animationController;

  String _colorKey(ProductVariant v) {
    final c = (v.color ?? '').trim();
    return c.isEmpty ? 'Default' : c;
  }

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

  /// The product carrying the currently selected variant's price/image/label —
  /// used when adding to cart or buying now.
  Product _effectiveProduct(Product product) {
    final v = _selectedVariant;
    if (v == null) return product;
    return product.copyWith(
      price: v.price,
      offerPrice: v.offerPrice,
      offerDiscountPercent: v.offerDiscountPercent,
      imageUrls: v.imageUrls.isNotEmpty ? v.imageUrls : product.imageUrls,
      variantLabel: [
        if ((v.color ?? '').trim().isNotEmpty) v.color!.trim(),
        v.label,
      ].join(' · '),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProductProvider>();
      // Re-fetch settings so admin trust-badge / delivery / tax edits show up
      // immediately instead of after the 60s background poll.
      if (mounted) {
        context.read<StoreSettingsProvider>().loadSettings(force: true);
        context.read<UserActivityProvider>().addRecentlyViewed(widget.productId);
      }
      // Always fetch full product (listing cache doesn't include specs /
      // description / variants). Keep showing a loader until this resolves so
      // we never flash "product not found" for a product that does exist.
      await provider.fetchProductById(widget.productId);
      if (mounted) setState(() => _detailLoading = false);
      // Related products come from a dedicated endpoint (the home flow doesn't
      // populate the provider's catalogue list).
      try {
        final rel = await ProductApiService()
            .getRelatedProducts(widget.productId, limit: 12);
        if (mounted) setState(() => _related = rel);
      } catch (_) {}
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
      // Show a loader while the detail fetch is still in flight (or the catalog
      // is still loading) — only fall back to "not found" once we've actually
      // tried and the product genuinely doesn't exist.
      if (_detailLoading ||
          productProvider.isLoading ||
          productProvider.allProducts.isEmpty) {
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

    // Pre-select a variant once they load, so the page opens on a concrete
    // colour + storage (matching the web). Prefer the admin-curated variant
    // passed in (e.g. the one whose offer the user tapped on a Today's Offers
    // card); fall back to the first variant.
    if (!_variantInitialized && product.variants.isNotEmpty) {
      _variantInitialized = true;
      final initial = widget.selectedVariantId == null
          ? product.variants.first
          : product.variants.firstWhere(
              (v) => v.id == widget.selectedVariantId,
              orElse: () => product.variants.first,
            );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedVariant = initial;
          _selectedColor = _colorKey(initial);
        });
      });
    }

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
                if (product.variants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildVariantSelector(product),
                ],
                const SizedBox(height: 12),
                _buildPriceRow(product),
                const SizedBox(height: 12),
                _buildQuantitySelector(),
                const SizedBox(height: 10),
                const TaxLabel(fontSize: 12),
                const SizedBox(height: 6),
                const DeliveryBadge(
                  fontSize: 13,
                  iconSize: 16,
                ),
                const SizedBox(height: 16),
                TrustBadgesRow(product: product),
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
          color: Colors.white,
          child: _buildProductImage(product.thumbnailUrl),
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
                  // White backdrop — product photos already sit on white, so a
                  // grey backdrop made white/light products (e.g. vivo 7) look
                  // greyed-over.
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  // No image_animation on the main detail image: animations like
                  // `fadeOut` end at 0.3 opacity and left the image permanently
                  // dimmed/greyed. The main product image must stay fully visible.
                  child: _buildProductImage(images[index]),
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
      // Show the whole product, sharp (no crop, high-quality scaling).
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
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
    // Append the selected colour + variant, e.g. "vivo 7 (Black, 128GB + 16GB
    // RAM)". Falls back to just the name when no variant is selected.
    var name = product.name;
    final v = _selectedVariant;
    if (v != null) {
      final parts = <String>[];
      final col = (v.color ?? '').trim();
      if (col.isNotEmpty) parts.add(col);
      if (v.label.isNotEmpty && v.label != col) parts.add(v.label);
      if (parts.isNotEmpty) name = '${product.name} (${parts.join(', ')})';
    }
    return Text(
      name,
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

  /// Two-level variant picker like the web: a COLOUR row (image swatches) and,
  /// below it, the STORAGE/RAM options for the selected colour. Picking either
  /// swaps the main image, price and discount in place.
  Widget _buildVariantSelector(Product product) {
    final variants = product.variants;
    if (variants.isEmpty) return const SizedBox.shrink();

    // Distinct colours, in order of appearance.
    final colours = <String>[];
    for (final v in variants) {
      final k = _colorKey(v);
      if (!colours.contains(k)) colours.add(k);
    }
    final selectedColour = _selectedColor ?? _colorKey(variants.first);
    final colourVariants =
        variants.where((v) => _colorKey(v) == selectedColour).toList();
    // Equal-width storage boxes — two per row.
    final boxW = (MediaQuery.sizeOf(context).width - 32 - 10) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- COLOUR ----
        if (colours.length > 1) ...[
          _variantHeading('Selected Color: ', selectedColour),
          const SizedBox(height: 10),
          // Smaller, wrapping thumbnails so every colour is visible at once —
          // no horizontal scrolling to discover variants.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colours.map((col) {
              final rep = variants.firstWhere((v) => _colorKey(v) == col);
              final selected = col == selectedColour;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedColor = col;
                  _selectedVariant = rep;
                  _selectedImageIndex = 0;
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1400E0)
                              : const Color(0xFFE2E8F0),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      padding: const EdgeInsets.all(4),
                      child: (rep.imageUrl.isNotEmpty ||
                              product.imageUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: rep.imageUrl.isNotEmpty
                                  ? rep.imageUrl
                                  : product.imageUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.phone_android,
                                  color: AppColors.textHint),
                            )
                          : const Icon(Icons.phone_android,
                              color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: Text(
                        col,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? const Color(0xFF1400E0)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        // ---- STORAGE / RAM (for the selected colour) ----
        _variantHeading('Variant: ', _selectedVariant?.label ?? ''),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colourVariants.map((v) {
            final selected = _selectedVariant?.id == v.id;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedVariant = v;
                _selectedImageIndex = 0;
              }),
              child: Container(
                width: boxW,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1400E0).withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF1400E0)
                        : const Color(0xFFE2E8F0),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (v.discountPercent > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '↓${v.discountPercent.toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyFormatter.format(v.price),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      CurrencyFormatter.format(v.effectivePrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      v.isOutOfStock ? 'Out of stock' : 'In stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: v.isOutOfStock
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _variantHeading(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
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
                      // Buy Now → straight to the order-summary page for THIS
                      // product (with its selected variant). It is NOT added to
                      // the cart — that's the Add-to-Cart flow. Mirrors mobile.
                      : () => context.push('/shop/order-summary',
                          extra: _effectiveProduct(product)),
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
            Column(
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
            const SizedBox(width: 10),
            // Add to Cart — compact icon button
            SizedBox(
              width: 48,
              height: 48,
              child: OutlinedButton(
                onPressed: product.isOutOfStock
                    ? null
                    : () {
                        // Add to cart → stay on the page so the user can keep
                        // shopping (standard flow). Already-in-cart taps open
                        // the cart.
                        if (isInCart) {
                          context.push('/shop/cart');
                          return;
                        }
                        final ep = _effectiveProduct(product);
                        for (int i = 0; i < _qty; i++) {
                          cart.addToCart(ep);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to cart'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'VIEW CART',
                              onPressed: () => context.push('/shop/cart'),
                            ),
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Icon(
                    isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                    size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Buy Now — primary action
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: product.isOutOfStock
                      ? null
                      : () {
                          // Straight to the order-summary page for THIS product
                          // (with its selected variant). It is NOT added to the
                          // cart — that happens only at Secure Checkout.
                          context.push('/shop/order-summary',
                              extra: _effectiveProduct(product));
                        },
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: Text(product.isOutOfStock ? 'Out of stock' : 'Buy Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
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
    // Prefer the dedicated related-products endpoint. Fall back to whatever the
    // provider has cached (home/listing/catalogue lists), deduped by id.
    final seen = <String>{product.id};
    final pool = <Product>[];
    for (final p in [
      ..._related,
      ...provider.homeProducts,
      ...provider.paginatedProducts,
      ...provider.allProducts,
    ]) {
      if (p.isActive && seen.add(p.id)) pool.add(p);
    }
    final similar = pool.take(10).toList();

    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You might also like',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        // Grid (no horizontal scrolling) — same card as the all-products grid.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: similar.length,
          itemBuilder: (_, i) => ProductCardMini(product: similar[i]),
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
