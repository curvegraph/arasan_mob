import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/glass_morphism.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/models/product.dart';
import '../../providers/cart_provider.dart';
import 'auth_gate.dart';
import 'image_placeholder.dart';

/// Premium quick-view modal.
///
/// Desktop: centered 580px dialog with backdrop blur + dark glass-morphism.
/// Mobile: draggable bottom sheet (70% screen height).
class QuickViewModal {
  QuickViewModal._();

  static void show(BuildContext context, Product product) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    if (isDesktop) {
      _showDesktopDialog(context, product);
    } else {
      _showMobileBottomSheet(context, product);
    }
  }

  // ---------------------------------------------------------------------------
  // DESKTOP DIALOG
  // ---------------------------------------------------------------------------
  static void _showDesktopDialog(BuildContext context, Product product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quick View',
      barrierColor: Colors.transparent, // We draw our own backdrop
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim, secondAnim, child) {
        final curvedAnim =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curvedAnim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _DesktopQuickView(product: product, animation: animation);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE BOTTOM SHEET
  // ---------------------------------------------------------------------------
  static void _showMobileBottomSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.70,
          maxChildSize: 0.90,
          minChildSize: 0.45,
          builder: (context, scrollController) {
            return _MobileQuickView(
              product: product,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// DESKTOP CONTENT
// =============================================================================
class _DesktopQuickView extends StatelessWidget {
  final Product product;
  final Animation<double> animation;

  const _DesktopQuickView({
    required this.product,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isInCart = cart.isInCart(product.id);
    final imageUrl = product.gifUrl ??
        (product.imageUrls.isNotEmpty ? product.imageUrls.first : null);

    return Stack(
      children: [
        // Backdrop blur layer
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12 * animation.value,
                    sigmaY: 12 * animation.value,
                  ),
                  child: Container(
                    color: Colors.black
                        .withValues(alpha: 0.45 * animation.value),
                  ),
                );
              },
            ),
          ),
        ),

        // Modal content
        Center(
          child: Material(
            color: Colors.transparent,
            child: GlassMorphism.dark(
              blur: 30,
              opacity: 0.82,
              borderRadius: BorderRadius.circular(AppSpacing.radiusModal),
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 580,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, right: 16),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Product image
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: ImagePlaceholder(
                            imageUrl: imageUrl,
                            icon: Icons.phone_android,
                            fit: BoxFit.cover,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Text content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand
                          Text(
                            product.brand.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Name
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Price
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.format(
                                    product.effectivePrice),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (product.offerPrice != null) ...[
                                const SizedBox(width: 10),
                                Text(
                                  CurrencyFormatter.format(product.price),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        Colors.white.withValues(alpha: 0.4),
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor:
                                        Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                              if (product.discountPercent > 0) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusRound),
                                  ),
                                  child: Text(
                                    '-${product.discountPercent.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Key specs (up to 4)
                          if (product.specs.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  product.specs.entries.take(4).map((entry) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      height: 1.3,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                      child: Column(
                        children: [
                          // Add to Cart button
                          if (!product.isOutOfStock)
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: () => requireAuth(
                                  context,
                                  message: 'Please login to add to cart',
                                  action: () async {
                                    if (!isInCart) await cart.addToCart(product);
                                  },
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                    color: isInCart
                                        ? AppColors.success
                                            .withValues(alpha: 0.15)
                                        : AppColors.accentBlue,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusButton),
                                    boxShadow: !isInCart
                                        ? [
                                            BoxShadow(
                                              color: AppColors.accentBlue
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isInCart
                                            ? Icons.check_circle_rounded
                                            : Icons.shopping_bag_outlined,
                                        color: isInCart
                                            ? AppColors.success
                                            : Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isInCart
                                            ? 'Added to Cart'
                                            : 'Add to Cart',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isInCart
                                              ? AppColors.success
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusButton),
                              ),
                              child: Text(
                                'Out of Stock',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),

                          // View Details link
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                context.push('/shop/product/${product.id}');
                              },
                              child: Text(
                                'View Full Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Colors.white.withValues(alpha: 0.5),
                                  decoration: TextDecoration.underline,
                                  decorationColor:
                                      Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// MOBILE CONTENT
// =============================================================================
class _MobileQuickView extends StatelessWidget {
  final Product product;
  final ScrollController scrollController;

  const _MobileQuickView({
    required this.product,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isInCart = cart.isInCart(product.id);
    final imageUrl = product.gifUrl ??
        (product.imageUrls.isNotEmpty ? product.imageUrls.first : null);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusModal)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusModal)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ImagePlaceholder(
                        imageUrl: imageUrl,
                        icon: Icons.phone_android,
                        fit: BoxFit.cover,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      Text(
                        product.brand.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Name
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price row
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(product.effectivePrice),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (product.offerPrice != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(product.price),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.4),
                                decoration: TextDecoration.lineThrough,
                                decorationColor:
                                    Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                          if (product.discountPercent > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusRound),
                              ),
                              child: Text(
                                '-${product.discountPercent.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Key specs
                      if (product.specs.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              product.specs.entries.take(4).map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Actions row
                      Row(
                        children: [
                          // Add to Cart
                          Expanded(
                            child: GestureDetector(
                              onTap: product.isOutOfStock
                                  ? null
                                  : () => requireAuth(
                                        context,
                                        message: 'Please login to add to cart',
                                        action: () async {
                                          if (!isInCart) await cart.addToCart(product);
                                        },
                                      ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: product.isOutOfStock
                                      ? Colors.white
                                          .withValues(alpha: 0.06)
                                      : isInCart
                                          ? AppColors.success
                                              .withValues(alpha: 0.15)
                                          : AppColors.accentBlue,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusButton),
                                  boxShadow:
                                      !product.isOutOfStock && !isInCart
                                          ? [
                                              BoxShadow(
                                                color: AppColors.accentBlue
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      product.isOutOfStock
                                          ? Icons.block_rounded
                                          : isInCart
                                              ? Icons.check_circle_rounded
                                              : Icons.shopping_bag_outlined,
                                      color: product.isOutOfStock
                                          ? Colors.white
                                              .withValues(alpha: 0.3)
                                          : isInCart
                                              ? AppColors.success
                                              : Colors.white,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      product.isOutOfStock
                                          ? 'Out of Stock'
                                          : isInCart
                                              ? 'Added'
                                              : 'Add to Cart',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: product.isOutOfStock
                                            ? Colors.white
                                                .withValues(alpha: 0.3)
                                            : isInCart
                                                ? AppColors.success
                                                : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // View Details
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                context
                                    .go('/shop/product/${product.id}');
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusButton),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  'View Details',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
