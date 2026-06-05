import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/homepage_config.dart';
import '../../../providers/homepage_provider.dart';

/// Auto-scrolling banner carousel with dynamic data.
/// Shows shimmer skeleton placeholders when no banners are configured.
class BannerSection extends StatefulWidget {
  final String sectionKey;
  final String? title;
  final Map<String, dynamic>? config;

  const BannerSection({
    super.key,
    this.sectionKey = 'banners',
    this.title,
    this.config,
  });

  @override
  State<BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  PageController? _pageController;
  int _controllerBannerCount = -1;
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier(0);
  Timer? _autoScrollTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController?.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  double _lastViewportFraction = -1;

  PageController _ensureController(int count, double viewportFraction) {
    if (_pageController != null &&
        _controllerBannerCount == count &&
        _lastViewportFraction == viewportFraction) {
      return _pageController!;
    }
    _pageController?.dispose();
    _pageController = PageController(viewportFraction: viewportFraction);
    _controllerBannerCount = count;
    _lastViewportFraction = viewportFraction;
    return _pageController!;
  }

  /// Pause/resume auto-scroll when section scrolls in/out of view
  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    if (visible) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final homepageProvider = context.read<HomepageProvider>();
    final section = homepageProvider.getSectionByKey(widget.sectionKey);
    final intervalSeconds =
        widget.config?['interval_seconds'] as int? ??
        section?.config['interval_seconds'] as int? ?? 5;

    _autoScrollTimer =
        Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (!_visible) return;
      final allBanners = context.read<HomepageProvider>().banners;

      // Check for inline banners first
      final activeBanners = (widget.config?['banners'] as List<dynamic>?)
          ?.where((b) {
            if (b is! Map) return false;
            final isActive = b['is_active'];
            return isActive == true || isActive == null;
          })
          .where((b) => b is Map && b['image_url'] != null)
          .map((b) {
            final map = b as Map;
            return BannerData(
              id: map['id']?.toString() ?? '',
              title: map['title']?.toString() ?? '',
              imageUrl: map['image_url']?.toString() ?? '',
              linkUrl: map['link_value']?.toString(),
              isAsset: false,
            );
          })
          .where((b) => b.imageUrl.isNotEmpty)
          .toList() ?? [];

      List<BannerData> banners;

      if (activeBanners.isNotEmpty) {
        banners = activeBanners;
      } else {
        final selectedBannerIds = (widget.config?['banners'] as List<dynamic>?)
            ?.map((e) => e is Map ? e['id']?.toString() : e.toString())
            .whereType<String>()
            .toList();

        if (selectedBannerIds != null && selectedBannerIds.isNotEmpty) {
          banners = selectedBannerIds
              .map((id) => allBanners.where((b) => b.id == id).firstOrNull)
              .whereType<BannerData>()
              .toList();
        } else {
          banners = allBanners;
        }
      }

      if (banners.isEmpty) return;

      final controller = _pageController;
      if (controller == null || !controller.hasClients) return;
      final nextPage = (_currentPageNotifier.value + 1) % banners.length;
      controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final homepageProvider = context.watch<HomepageProvider>();
    final allBanners = homepageProvider.banners;
    final width = MediaQuery.sizeOf(context).width;

    // Check for inline banners in config (uploaded directly in homepage editor)
    final inlineBanners = (widget.config?['banners'] as List<dynamic>?)
        ?.where((b) => b is Map && b['image_url'] != null && b['is_active'] != false)
        .map((b) {
          final map = b as Map;
          return BannerData(
            id: map['id']?.toString() ?? '',
            title: map['title']?.toString() ?? '',
            imageUrl: map['image_url']?.toString() ?? '',
            linkUrl: map['link_value']?.toString(),
            isAsset: false,
          );
        })
        .where((b) => b.imageUrl.isNotEmpty)
        .toList();

    // Filter inline banners by is_active
    final activeBanners = (widget.config?['banners'] as List<dynamic>?)
        ?.where((b) {
          if (b is! Map) return false;
          final isActive = b['is_active'];
          return isActive == true || isActive == null; // Default to active
        })
        .where((b) => b is Map && b['image_url'] != null)
        .map((b) {
          final map = b as Map;
          return BannerData(
            id: map['id']?.toString() ?? '',
            title: map['title']?.toString() ?? '',
            imageUrl: map['image_url']?.toString() ?? '',
            linkUrl: map['link_value']?.toString(),
            isAsset: false,
          );
        })
        .where((b) => b.imageUrl.isNotEmpty)
        .toList() ?? [];

    List<BannerData> banners;

    if (activeBanners.isNotEmpty) {
      // Use inline banners from homepage editor
      banners = activeBanners;
    } else {
      // Fall back to banners from database
      final selectedBannerIds = (widget.config?['banners'] as List<dynamic>?)
          ?.map((e) => e is Map ? e['id']?.toString() : e.toString())
          .whereType<String>()
          .toList();

      if (selectedBannerIds != null && selectedBannerIds.isNotEmpty) {
        // Show only selected banners in the order they were selected
        banners = selectedBannerIds
            .map((id) => allBanners.where((b) => b.id == id).firstOrNull)
            .whereType<BannerData>()
            .toList();
      } else {
        // Show all banners from database
        banners = allBanners;
      }
    }

    // Card aspect ratio must match admin auto-crop target (2:1 Flipkart-style)
    // so uploaded banners fit with no letterbox or crop.
    const double kBannerAspect = 2.0;
    final double viewportFraction;
    if (banners.length <= 1) {
      viewportFraction = width < 600 ? 0.94 : (width < 1000 ? 0.70 : 0.50);
    } else if (width < 600) {
      viewportFraction = 0.92;
    } else if (width < 1000) {
      viewportFraction = 0.62;
    } else {
      // 3 cards visible with peek — Flipkart desktop layout
      viewportFraction = 0.34;
    }
    final double height = (width * viewportFraction) / kBannerAspect;

    if (banners.isEmpty) {
      return _SkeletonBannerCarousel(height: height);
    }

    final controller = _ensureController(banners.length, viewportFraction);

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            child: PageView.builder(
              controller: controller,
              onPageChanged: (index) {
                _currentPageNotifier.value = index;
              },
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return _BannerItem(banner: banner);
              },
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: _currentPageNotifier,
            builder: (context, currentPage, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length,
                  (index) => _Indicator(isActive: index == currentPage),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Single banner item
class _BannerItem extends StatelessWidget {
  final BannerData banner;

  const _BannerItem({required this.banner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
          debugPrint('Navigate to: ${banner.linkUrl}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image fills the whole banner card
              if (banner.imageUrl.isNotEmpty)
                banner.isAsset
                    ? Image.asset(
                        banner.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _BannerLoadingPlaceholder(),
                      )
                    : CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.medium,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (_, __) => _BannerLoadingPlaceholder(),
                        errorWidget: (_, __, ___) => _BannerLoadingPlaceholder(),
                      )
              else
                _BannerLoadingPlaceholder(),

            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder shown while a banner image is loading
class _BannerLoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// Skeleton shimmer banner carousel — shown when admin hasn't added banners yet.
/// Auto-scrolls through 3 different skeleton slides with shimmer animation.
class _SkeletonBannerCarousel extends StatefulWidget {
  final double height;
  const _SkeletonBannerCarousel({required this.height});

  @override
  State<_SkeletonBannerCarousel> createState() =>
      _SkeletonBannerCarouselState();
}

class _SkeletonBannerCarouselState extends State<_SkeletonBannerCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  static const _slideCount = 3;

  // Each slide has a different color tint and layout variation
  static const _slideColors = [
    (base: Color(0xFFDDE3ED), highlight: Color(0xFFF0F4FA), accent: Color(0xFFCDD5E1)),
    (base: Color(0xFFD4E4F7), highlight: Color(0xFFEBF2FC), accent: Color(0xFFC0D4EA)),
    (base: Color(0xFFDDE8D6), highlight: Color(0xFFF0F6EC), accent: Color(0xFFC8D9C0)),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _slideCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Auto-scrolling skeleton pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slideCount,
            itemBuilder: (context, index) {
              final colors = _slideColors[index];
              return _SkeletonSlide(
                baseColor: colors.base,
                highlightColor: colors.highlight,
                accentColor: colors.accent,
                variant: index,
              );
            },
          ),

          // Animated page indicators
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slideCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentPage ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single skeleton slide with shimmer — layout varies by [variant].
class _SkeletonSlide extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;
  final Color accentColor;
  final int variant;

  const _SkeletonSlide({
    required this.baseColor,
    required this.highlightColor,
    required this.accentColor,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: baseColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          period: const Duration(milliseconds: 1500),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: baseColor),
              // Build different skeleton layouts per slide
              ..._buildVariant(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVariant() {
    switch (variant) {
      case 0:
        // Layout: image icon center + text bottom-left
        return [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.image_outlined, size: 30, color: accentColor),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(180, 16),
                const SizedBox(height: 8),
                _bar(130, 11),
                const SizedBox(height: 12),
                _bar(100, 30, radius: 8),
              ],
            ),
          ),
        ];

      case 1:
        // Layout: text top-left + large image placeholder right
        return [
          Positioned(
            left: 20,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(140, 18),
                const SizedBox(height: 8),
                _bar(200, 12),
                const SizedBox(height: 6),
                _bar(160, 12),
                const SizedBox(height: 14),
                _bar(110, 32, radius: 8),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            bottom: 20,
            child: Container(
              width: 110,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.smartphone, size: 40, color: accentColor),
            ),
          ),
        ];

      case 2:
      default:
        // Layout: centered text + two small image boxes
        return [
          Positioned(
            left: 20,
            bottom: 28,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(160, 18),
                const SizedBox(height: 8),
                _bar(220, 12),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _bar(90, 32, radius: 8),
                    const SizedBox(width: 10),
                    _bar(90, 32, radius: 8),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }

  Widget _bar(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Page indicator dot
class _Indicator extends StatelessWidget {
  final bool isActive;

  const _Indicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
