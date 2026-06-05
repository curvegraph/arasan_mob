import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/auth_gate.dart';
import '../../../shared/widgets/delivery_badge.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showAssured;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showAssured = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: compact ? 3 : 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.phone_android, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Wishlist icon - top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer2<WishlistProvider, AuthProvider>(
                      builder: (context, wishlist, auth, _) {
                        final isInWishlist = wishlist.isInWishlist(product.id);
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
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isInWishlist ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Discount badge - top left
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${product.discountPercent}% OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details section
            Expanded(
              flex: compact ? 2 : 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Rating row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.star, size: 9, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${_formatCount(product.reviewCount)})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (showAssured) ...[
                          const Spacer(),
                          _buildAssuredBadge(),
                        ],
                      ],
                    ),
                    // Price row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(product.effectivePrice),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        if (product.hasDiscount)
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.format(product.price),
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${product.discountPercent.toStringAsFixed(0)}% off',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Delivery info — driven by admin's store_settings.
                    const DeliveryBadge(
                      fontSize: 10,
                      iconSize: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssuredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2874F0).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 10,
            color: const Color(0xFF2874F0),
          ),
          const SizedBox(width: 2),
          const Text(
            'Assured',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2874F0),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

/// Horizontal product card for deal sections
class ProductCardHorizontal extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCardHorizontal({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.phone_android, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${product.discountPercent}% OFF',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(product.effectivePrice),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    if (product.hasDiscount)
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: TextStyle(
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini product card for compact grids
class ProductCardMini extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCardMini({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.phone_android, size: 30, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${CurrencyFormatter.format(product.effectivePrice)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
