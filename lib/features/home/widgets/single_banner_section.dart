import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Single banner section that displays one banner image with optional click action.
class SingleBannerSection extends StatelessWidget {
  final String sectionKey;
  final String? title;
  final Map<String, dynamic>? config;

  const SingleBannerSection({
    super.key,
    this.sectionKey = 'single_banner',
    this.title,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = config?['image_url'] as String?;
    final clickAction = config?['click_action'] as String? ?? 'none';
    final clickValue = config?['click_value']?.toString() ?? '';

    if (imageUrl == null || imageUrl.isEmpty) {
      // Show placeholder when no image — 3:1 to match the cropped banner ratio.
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AspectRatio(
          aspectRatio: 3 / 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _handleTap(context, clickAction, clickValue),
      child: Container(
        // Full-width, edge-to-edge banner (no side margin / rounded corners).
        margin: const EdgeInsets.symmetric(vertical: 8),
        // Hero banner is cropped to 3:1 in the admin tool; render at the same
        // ratio so BoxFit.cover doesn't trim what the admin chose to show.
        child: AspectRatio(
          aspectRatio: 3 / 1,
          child: SizedBox(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: AppColors.primaryLight.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.primaryLight.withOpacity(0.1),
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, String action, String value) {
    if (action == 'none' || value.isEmpty) return;

    switch (action) {
      case 'category':
        context.push('/category/$value');
        break;
      case 'brand':
        context.push('/brand/$value');
        break;
      case 'product':
        context.push('/product/$value');
        break;
      case 'url':
        // Open external URL - could use url_launcher
        debugPrint('Open URL: $value');
        break;
      case 'screen':
        _navigateToScreen(context, value);
        break;
    }
  }

  void _navigateToScreen(BuildContext context, String screen) {
    switch (screen) {
      case 'home':
        context.go('/shop');
        break;
      case 'categories':
        context.push('/categories');
        break;
      case 'brands':
        context.push('/brands');
        break;
      case 'cart':
        context.push('/cart');
        break;
      case 'orders':
        context.push('/orders');
        break;
      case 'wishlist':
        context.push('/shop/account?tab=1');
        break;
      case 'profile':
        context.push('/profile');
        break;
    }
  }
}
