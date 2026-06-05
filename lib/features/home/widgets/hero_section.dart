import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/responsive_helper.dart';

class _BannerData {
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
  });
}

const _banners = <_BannerData>[
  _BannerData(
    title: 'Arasan\nMobiles',
    subtitle: 'Browse our collection of smartphones and accessories.',
    buttonText: 'Shop Now',
    icon: Icons.phone_android,
    backgroundColor: Color(0xFFF5F0E8),
    textColor: Color(0xFF2D2D2D),
    buttonColor: Color(0xFF2D2D2D),
  ),
  _BannerData(
    title: 'New Arrivals',
    subtitle: 'Check out the latest smartphones in our store.',
    buttonText: 'Explore',
    icon: Icons.new_releases,
    backgroundColor: Color(0xFFF0E8F5),
    textColor: Color(0xFF2D2D2D),
    buttonColor: Color(0xFF6A1B9A),
  ),
];

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final bannerHeight = isMobile ? 250.0 : 320.0;

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildBannerSlide(_banners[index], isMobile);
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _banners.length,
                effect: ExpandingDotsEffect(
                  dotWidth: 8,
                  dotHeight: 8,
                  spacing: 6,
                  expansionFactor: 3,
                  activeDotColor: AppColors.textPrimary,
                  dotColor: AppColors.textHint.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlide(_BannerData banner, bool isMobile) {
    return Container(
      color: banner.backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.xl : 48.0,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        children: [
          // Left side: Text content
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    color: banner.textColor,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                Text(
                  banner.subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    color: banner.textColor.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
                GestureDetector(
                  onTap: () => context.push('/shop/products'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: banner.buttonColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      banner.buttonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Right side: Illustration placeholder
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: isMobile ? 120 : 180,
                height: isMobile ? 120 : 180,
                decoration: BoxDecoration(
                  color: banner.textColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  banner.icon,
                  size: isMobile ? 56 : 80,
                  color: banner.textColor.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
