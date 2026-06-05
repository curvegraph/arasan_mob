import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import 'auth_gate.dart';

/// Compact product card for grids — optimized for scroll performance
class CompactProductCard extends StatelessWidget {
  final Product product;
  final double? width;
  final bool showWishlist;
  final bool showAddToCart;

  const CompactProductCard({
    super.key,
    required this.product,
    this.width,
    this.showWishlist = true,
    this.showAddToCart = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.hardEdge,
        elevation: 0,
        child: InkWell(
          onTap: () => context.push('/shop/product/${product.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image — lightweight, no CachedNetworkImage overhead
              Expanded(
                child: _FastImage(
                  imageUrl: product.imageUrl,
                  hasDiscount: product.hasDiscount,
                  discountPercent: product.discountPercent,
                  isOutOfStock: product.isOutOfStock,
                  showWishlist: showWishlist,
                  productId: product.id,
                ),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.brand.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _PriceRow(product: product),
                    if (showAddToCart) ...[
                      const SizedBox(height: 6),
                      _CartButtons(product: product),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight image widget — no animations, no state, maximum scroll performance.
class _FastImage extends StatelessWidget {
  final String imageUrl;
  final bool hasDiscount;
  final double discountPercent;
  final bool isOutOfStock;
  final bool showWishlist;
  final String productId;

  const _FastImage({
    required this.imageUrl,
    required this.hasDiscount,
    required this.discountPercent,
    required this.isOutOfStock,
    required this.showWishlist,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        const ColoredBox(color: Color(0xFFF5F5F5)),

        // Product Image — no animations, just show it
        if (imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            cacheWidth: 300,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.smartphone, size: 36, color: AppColors.textTertiary),
            ),
          )
        else
          const Center(
            child: Icon(Icons.smartphone, size: 36, color: AppColors.textTertiary),
          ),

        // Discount Badge
        if (hasDiscount)
          Positioned(
            top: 8,
            left: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  '${discountPercent.toInt()}% OFF',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        // Out of Stock
        if (isOutOfStock)
          ColoredBox(
            color: Colors.white70,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Wishlist
        if (showWishlist)
          Positioned(
            top: 8,
            right: 8,
            child: _WishlistButton(productId: productId),
          ),
      ],
    );
  }
}

/// Cart buttons — isolated widget so cart state changes only rebuild this
class _CartButtons extends StatelessWidget {
  final Product product;
  const _CartButtons({required this.product});

  @override
  Widget build(BuildContext context) {
    final isInCart = context.select<CartProvider, bool>(
      (c) => c.isInCart(product.id),
    );
    final cart = context.read<CartProvider>();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 30,
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
                backgroundColor: isInCart ? AppColors.success : AppColors.primaryLight,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                product.isOutOfStock
                    ? 'Out of Stock'
                    : isInCart
                        ? 'Go to Cart'
                        : 'Add to Cart',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 30,
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
                disabledBackgroundColor: AppColors.border,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Isolated wishlist button
class _WishlistButton extends StatelessWidget {
  final String productId;
  const _WishlistButton({required this.productId});

  @override
  Widget build(BuildContext context) {
    final isWishlisted = context.select<WishlistProvider, bool>(
      (w) => w.isInWishlist(productId),
    );

    return GestureDetector(
      onTap: () => requireAuth(context, action: () async {
        await context.read<WishlistProvider>().toggleWishlist(productId);
      }),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWishlisted ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isWishlisted ? AppColors.wishlistRed : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Price display row
class _PriceRow extends StatelessWidget {
  final Product product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '\u20B9${_formatPrice(product.effectivePrice)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 6),
          Text(
            '\u20B9${_formatPrice(product.price)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(2)}L';
    } else if (price >= 1000) {
      final formatted = price.toStringAsFixed(0);
      final buffer = StringBuffer();
      int count = 0;
      for (int i = formatted.length - 1; i >= 0; i--) {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          buffer.write(',');
        }
        buffer.write(formatted[i]);
        count++;
      }
      return buffer.toString().split('').reversed.join();
    }
    return price.toStringAsFixed(0);
  }
}
