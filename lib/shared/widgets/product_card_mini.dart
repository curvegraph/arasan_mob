import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_formatter.dart';
import '../../data/models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import 'animated_product_image.dart';
import 'auth_gate.dart';
import 'image_placeholder.dart';

/// Product card matching the SvelteKit storefront design — pastel hero image,
/// hanging discount tag, optional featured badge, brand+rating row, price +
/// savings pill, and a split Add/Buy CTA bar with arrow tab.
class ProductCardMini extends StatefulWidget {
  final Product product;
  final double? width;
  final int staggerIndex;

  const ProductCardMini({
    super.key,
    required this.product,
    this.width,
    this.staggerIndex = 0,
  });

  @override
  State<ProductCardMini> createState() => _ProductCardMiniState();
}

class _ProductCardMiniState extends State<ProductCardMini> {
  int _hoverIndex = 0;
  bool _hovered = false;
  bool _justAdded = false;

  static const _brandColor = Color(0xFF1400E0);
  static const _brandLight = Color(0xFF2962FF);
  static const _brandDark = Color(0xFF0D00B3);
  static const _success = Color(0xFF16A34A);
  static const _wishlistRed = Color(0xFFEF4444);

  // Trust the backend's advertised offer percent (Product.discountPercent),
  // which uses offer_discount_percent when set and only falls back to a
  // price-ratio calc. Computing purely from price/offerPrice here showed the
  // wrong number (e.g. 6% instead of the offer's real 15%) whenever a
  // max-discount cap limited the rupee saving below the advertised percent.
  int get _discountPercent => widget.product.discountPercent.round();

  Future<void> _toggleWishlist() async {
    final wp = context.read<WishlistProvider>();
    await requireAuth(context, action: () async {
      await wp.toggleWishlist(widget.product.id);
    });
  }

  Future<void> _addToCart() async {
    if (widget.product.isOutOfStock) return;
    // Add and stay (with a brief "added" state) so the user keeps shopping.
    await context.read<CartProvider>().addToCart(widget.product);
    if (!mounted) return;
    setState(() => _justAdded = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  Future<void> _buyNow() async {
    if (widget.product.isOutOfStock) return;
    // Straight to the order-summary page; not added to the cart.
    context.push('/shop/order-summary', extra: widget.product);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final wishlistProvider = context.watch<WishlistProvider>();
    final isWishlisted = wishlistProvider.isInWishlist(p.id);
    final discount = _discountPercent;
    final outOfStock = p.isOutOfStock;
    final hasRating = p.rating > 0;
    final images = p.imageUrls;
    final imageCount = images.length.clamp(0, 3);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _hoverIndex = 0;
      }),
      child: GestureDetector(
        onTap: () => context.push(
          p.selectedVariantId == null
              ? '/shop/product/${p.id}'
              : '/shop/product/${p.id}?variant=${p.selectedVariantId}',
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(0.0, _hovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovered
                  ? _brandColor.withOpacity(0.40)
                  : const Color(0xFFE2E8F0).withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? _brandColor.withOpacity(0.08)
                    : Colors.black.withOpacity(0.03),
                blurRadius: _hovered ? 20 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImage(images, imageCount, discount, outOfStock),
              // Compact body — CTA bar sits directly under the price with no
              // Spacer. Name is reserved at 2 lines so cards on the same row
              // stay aligned regardless of title length, but the extra line is
              // tight (fontSize 12) so a 1-line name doesn't create a big gap.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.brand.isNotEmpty || hasRating) _buildBrandRow(p, hasRating),
                    const SizedBox(height: 2),
                    // Single line + ellipsis — every card has the same content
                    // height regardless of title length, so CTAs align across
                    // the row with no reserved blank space anywhere. Long
                    // titles truncate; the full name is on the detail page.
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.2,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildPriceRow(p, discount),
                    const SizedBox(height: 5),
                    _buildCTABar(outOfStock, isWishlisted),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        ),
      ),
    );
  }

  Widget _buildImage(
    List<String> images,
    int imageCount,
    int discount,
    bool outOfStock,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Container(color: Colors.white),
            // Cross-fade between up to 3 images
            if (imageCount > 0)
              for (int i = 0; i < imageCount; i++)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _hoverIndex == i ? 1.0 : 0.0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    scale: _hoverIndex == i ? 1.05 : 1.0,
                    child: SizedBox.expand(
                      // Primary image plays the product's admin-set animation
                      // (bounce/pulse/zoom/...). Hover-swap images stay static.
                      child: i == 0 &&
                              widget.product.imageAnimation != ImageAnimation.none
                          // Animated image: inset + contain so the looping
                          // zoom/bounce has headroom and never clips the product
                          // off at the edges.
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: AnimatedProductImage(
                                animation: widget.product.imageAnimation,
                                child: ImagePlaceholder(
                                  imageUrl: images[i],
                                  icon: Icons.phone_android,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : ImagePlaceholder(
                              imageUrl: images[i],
                              icon: Icons.phone_android,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                )
            else
              const Center(
                child: Text('📱', style: TextStyle(fontSize: 48)),
              ),

            if (discount > 0)
              Positioned(
                top: 8,
                left: 8,
                child: _DiscountTag(percent: discount),
              ),
            if (widget.product.isFeatured)
              Positioned(
                top: discount > 0 ? 56 : 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _brandColor.withOpacity(0.20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    '★ Featured',
                    style: TextStyle(
                      color: _brandColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

            // Wishlist heart top-right
            Positioned(
              top: 8,
              right: 8,
              child: _buildWishlistButton(),
            ),

            // Hover hotspots — top half split into N equal columns
            if (imageCount > 1)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Row(
                  children: List.generate(imageCount, (i) {
                    return Expanded(
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoverIndex = i),
                        child: const SizedBox.expand(),
                      ),
                    );
                  }),
                ),
              ),

            // Image dot indicators
            if (imageCount > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(imageCount, (i) {
                    final isActive = _hoverIndex == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        width: isActive ? 18 : 5,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive ? _brandColor : const Color(0xFFCBD5E1),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            if (outOfStock)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    final isWishlisted =
        context.watch<WishlistProvider>().isInWishlist(widget.product.id);
    return GestureDetector(
      onTap: _toggleWishlist,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          border: Border.all(
            color: isWishlisted
                ? _wishlistRed
                : const Color(0xFFE2E8F0).withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          isWishlisted ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: isWishlisted ? _wishlistRed : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildBrandRow(Product p, bool hasRating) {
    return Row(
      children: [
        Expanded(
          child: Text(
            p.brand.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _brandColor,
              letterSpacing: 1.0,
            ),
          ),
        ),
        if (hasRating) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _success,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.star, size: 9, color: Colors.white),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRow(Product p, int discount) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: [
        Text(
          CurrencyFormatter.format(p.effectivePrice),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            height: 1.0,
            letterSpacing: -0.3,
          ),
        ),
        // Struck original shows whenever a sale OR offer applies (hasDiscount).
        // The hanging "% OFF" tag on the image is separate and offer-only.
        if (p.hasDiscount)
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(
              CurrencyFormatter.format(p.price),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCTABar(bool outOfStock, bool isWishlisted) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: outOfStock ? null : _addToCart,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: _justAdded ? _success.withOpacity(0.10) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: outOfStock
                      ? const Color(0xFFE2E8F0)
                      : _justAdded
                          ? _success
                          : _brandColor.withOpacity(0.30),
                  width: 2,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _justAdded ? Icons.check : Icons.shopping_cart_outlined,
                      size: 13,
                      color: outOfStock
                          ? const Color(0xFFCBD5E1)
                          : _justAdded
                              ? _success
                              : _brandColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _justAdded ? 'Added' : 'Add',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: outOfStock
                            ? const Color(0xFFCBD5E1)
                            : _justAdded
                                ? _success
                                : _brandColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: outOfStock ? null : _buyNow,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                gradient: outOfStock
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_brandColor, _brandLight],
                      ),
                color: outOfStock ? const Color(0xFFE2E8F0) : null,
                borderRadius: BorderRadius.circular(999),
                boxShadow: outOfStock
                    ? null
                    : [
                        BoxShadow(
                          color: _brandColor.withOpacity(0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 12,
                            color: outOfStock
                                ? const Color(0xFFCBD5E1)
                                : Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Buy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: outOfStock
                                  ? const Color(0xFFCBD5E1)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: outOfStock
                              ? const Color(0xFFCBD5E1)
                              : _brandColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hanging discount tag with little tail at the bottom-left corner.
class _DiscountTag extends StatelessWidget {
  final int percent;
  const _DiscountTag({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1400E0), Color(0xFF2962FF)],
            ),
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1400E0).withOpacity(0.40),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'OFF',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 6,
          bottom: -3,
          child: Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 8,
              height: 8,
              color: const Color(0xFF2962FF),
            ),
          ),
        ),
      ],
    );
  }
}
