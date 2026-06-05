import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Returns a category-specific icon based on category name.
IconData getCategoryIcon(String? category) {
  if (category == null || category.isEmpty) return Icons.shopping_bag_outlined;

  final cat = category.toLowerCase();

  if (cat.contains('smart') || cat.contains('phone') || cat.contains('mobile')) {
    return Icons.phone_android;
  }
  if (cat.contains('laptop') || cat.contains('notebook') || cat.contains('computer')) {
    return Icons.laptop;
  }
  if (cat.contains('tablet') || cat.contains('ipad')) {
    return Icons.tablet_android;
  }
  if (cat.contains('headphone') || cat.contains('earbud') || cat.contains('audio')) {
    return Icons.headphones;
  }
  if (cat.contains('watch') || cat.contains('wearable')) {
    return Icons.watch;
  }
  if (cat.contains('tv') || cat.contains('television')) {
    return Icons.tv;
  }
  if (cat.contains('camera') || cat.contains('photo')) {
    return Icons.camera_alt_outlined;
  }
  if (cat.contains('gaming') || cat.contains('console')) {
    return Icons.sports_esports;
  }
  if (cat.contains('speaker')) {
    return Icons.speaker;
  }
  if (cat.contains('charger') || cat.contains('cable') || cat.contains('adapter')) {
    return Icons.cable;
  }
  if (cat.contains('accessori')) {
    return Icons.devices_other;
  }
  if (cat.contains('power') || cat.contains('bank')) {
    return Icons.battery_charging_full;
  }
  if (cat.contains('case') || cat.contains('cover')) {
    return Icons.phone_iphone;
  }

  return Icons.shopping_bag_outlined;
}

/// Vertical shimmer placeholder card matching the screenshot design.
/// Shows a category-specific icon in the image area with shimmer effect.
class ProductPlaceholderCard extends StatelessWidget {
  final String? category;

  const ProductPlaceholderCard({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    final icon = getCategoryIcon(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area with category icon
          Expanded(
            flex: 55,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 44,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                // Heart icon
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Shimmer text area
          Expanded(
            flex: 45,
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE2E8F0),
              highlightColor: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Brand
                    _bar(width: 45, height: 8),
                    // Product name (2 lines)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(width: double.infinity, height: 10),
                        const SizedBox(height: 4),
                        _bar(width: 80, height: 10),
                      ],
                    ),
                    // Rating badge + count
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _bar(width: 30, height: 7),
                      ],
                    ),
                    // Price
                    _bar(width: 70, height: 13),
                    // MRP + discount
                    Row(
                      children: [
                        _bar(width: 48, height: 9),
                        const SizedBox(width: 6),
                        Container(
                          width: 38,
                          height: 9,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    // Free delivery
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 11,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 4),
                        _bar(width: 55, height: 7),
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

  static Widget _bar({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Horizontal shimmer placeholder card matching ProductListCard layout.
/// Used on the product listing page (Flipkart-style list view).
class ProductListPlaceholderCard extends StatelessWidget {
  final String? category;

  const ProductListPlaceholderCard({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    final icon = getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image area with category icon
          SizedBox(
            width: 120,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 44,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                // Heart icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Shimmer text area
          Expanded(
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE2E8F0),
              highlightColor: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    _bar(width: 50, height: 8),
                    const SizedBox(height: 8),
                    // Product name (2 lines)
                    _bar(width: double.infinity, height: 11),
                    const SizedBox(height: 5),
                    _bar(width: 140, height: 11),
                    const SizedBox(height: 10),
                    // Rating badge + count
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _bar(width: 30, height: 8),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Price row
                    Row(
                      children: [
                        _bar(width: 70, height: 14),
                        const SizedBox(width: 8),
                        _bar(width: 48, height: 10),
                        const SizedBox(width: 6),
                        Container(
                          width: 40,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Spec tags
                    Row(
                      children: [
                        _specTag(width: 55),
                        const SizedBox(width: 6),
                        _specTag(width: 65),
                        const SizedBox(width: 6),
                        _specTag(width: 50),
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

  static Widget _bar({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static Widget _specTag({required double width}) {
    return Container(
      width: width,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
