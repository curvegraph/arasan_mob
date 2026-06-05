import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product.dart';
import '../../../data/services/product_service.dart';
import '../../../providers/homepage_provider.dart';

/// Flash Deals section — gradient background, countdown timer, auto-scrolling carousel.
/// Fetches only the deal products it needs (not the full catalog).
class DealsSection extends StatefulWidget {
  final String sectionKey;
  final String? title;
  final Map<String, dynamic>? config;

  const DealsSection({
    super.key,
    this.sectionKey = 'flash_deals',
    this.title,
    this.config,
  });

  @override
  State<DealsSection> createState() => _DealsSectionState();
}

class _DealsSectionState extends State<DealsSection> {
  late Timer _countdownTimer;
  final ValueNotifier<Duration> _timeLeftNotifier = ValueNotifier(Duration.zero);

  late final ScrollController _scrollController;
  bool _visible = true;

  // Products loaded directly (not from productProvider.allProducts)
  final ProductService _productService = ProductService();
  List<Product> _dealsProducts = [];
  bool _isLoadingProducts = true;
  Timer? _productsPollTimer;

  // Section-specific timer config
  DateTime? _endTime;
  bool _showTimer = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _parseTimerConfig();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDealProducts();
    });

    // Polling-based refresh (Socket.IO bridge will replace this).
    _productsPollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadDealProducts();
    });
  }

  void _parseTimerConfig() {
    // Read timer config from section config
    // Default to true for backwards compatibility (timer was always shown before)
    _showTimer = widget.config?['show_timer'] ?? true;
    final endTimeStr = widget.config?['end_time'] as String?;
    if (endTimeStr != null && endTimeStr.isNotEmpty) {
      try {
        _endTime = DateTime.parse(endTimeStr);
      } catch (e) {
        debugPrint('[DealsSection] Failed to parse end_time: $endTimeStr');
      }
    }

    // If timer is enabled but no end time set, default to midnight tonight
    if (_showTimer && _endTime == null) {
      final now = DateTime.now();
      _endTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
      // If already past midnight, set to next day
      if (_endTime!.isBefore(now)) {
        _endTime = _endTime!.add(const Duration(days: 1));
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _scrollController.dispose();
    _timeLeftNotifier.dispose();
    _productsPollTimer?.cancel();
    _productsPollTimer = null;
    super.dispose();
  }

  /// Fetch only the products needed for this deals section
  Future<void> _loadDealProducts() async {
    final homepageProvider = context.read<HomepageProvider>();
    final flashDeal = homepageProvider.flashDeal;
    final section = homepageProvider.getSectionByKey(widget.sectionKey);
    final maxItems = section?.maxItems ?? 10;

    List<Product> products = [];

    try {
      // Check section config for selected product IDs
      final selectedProductIds = (widget.config?['selected_product_ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();

      if (selectedProductIds != null && selectedProductIds.isNotEmpty) {
        products = await _productService.getProductsByIds(selectedProductIds);
        products = products.take(maxItems).toList();
      } else if (flashDeal != null && flashDeal.isActive) {
        if (flashDeal.productIds.isNotEmpty) {
          products = await _productService.getProductsByIds(flashDeal.productIds);
          products = products.take(maxItems).toList();
        } else if (flashDeal.filterType == 'category' && flashDeal.filterValue != null) {
          products = await _productService.getProductsByCategoryLimited(
            flashDeal.filterValue!,
            limit: maxItems,
          );
        } else if (flashDeal.filterType == 'brand' && flashDeal.filterValue != null) {
          products = await _productService.getProductsByBrandLimited(
            flashDeal.filterValue!,
            limit: maxItems,
          );
        }
      }
    } catch (e) {
      debugPrint('[DealsSection] Error loading products: $e');
    }

    if (mounted) {
      setState(() {
        _dealsProducts = products;
        _isLoadingProducts = false;
      });
    }
  }

  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    if (visible) {
      _startCountdown();
    } else {
      _countdownTimer.cancel();
    }
  }

  void _startCountdown() {
    // Update immediately on first call
    _updateTimeLeft();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_visible) return;
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    // First check section-specific timer config
    if (_showTimer && _endTime != null) {
      final now = DateTime.now();
      if (_endTime!.isAfter(now)) {
        _timeLeftNotifier.value = _endTime!.difference(now);
      } else {
        _timeLeftNotifier.value = Duration.zero;
      }
      return;
    }

    // Fall back to global flash deal config
    final flashDeal = context.read<HomepageProvider>().flashDeal;
    if (flashDeal != null && flashDeal.isActive) {
      _timeLeftNotifier.value = flashDeal.timeRemaining;
    }
  }

  @override
  Widget build(BuildContext context) {
    final homepageProvider = context.read<HomepageProvider>();
    final flashDeal = homepageProvider.flashDeal;
    final section = homepageProvider.getSectionByKey(widget.sectionKey);
    final isDaily = section?.type == 'daily_deals';
    final defaultTitle = isDaily ? 'Daily Deals' : 'Flash Deals';
    final title = flashDeal?.title ?? section?.title ?? defaultTitle;

    if (_isLoadingProducts || _dealsProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    debugPrint('[DealsSection] ${widget.sectionKey}: Building with ${_dealsProducts.length} products');

    final bandColor = isDaily ? const Color(0xFF2962FF) : const Color(0xFFF0593F);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;
    final cardWidth = isWide ? 170.0 : 130.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bandColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.fromLTRB(isWide ? 20 : 16, 14, isWide ? 20 : 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isWide ? 20 : 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              ValueListenableBuilder<Duration>(
                valueListenable: _timeLeftNotifier,
                builder: (context, timeLeft, _) {
                  if (timeLeft.inSeconds <= 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TimerBadge(timeLeft: timeLeft),
                  );
                },
              ),
              GestureDetector(
                onTap: () => context.push('/shop/offers'),
                child: Container(
                  width: isWide ? 36 : 32,
                  height: isWide ? 36 : 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: cardWidth + 70,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _dealsProducts.length,
              separatorBuilder: (_, __) => SizedBox(width: isWide ? 12 : 10),
              itemBuilder: (_, index) => SizedBox(
                width: cardWidth,
                child: _DealProductCard(product: _dealsProducts[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DealProductCard extends StatefulWidget {
  final Product product;
  const _DealProductCard({required this.product});

  @override
  State<_DealProductCard> createState() => _DealProductCardState();
}

class _DealProductCardState extends State<_DealProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final discount = p.discountPercent.toInt();
    final outOfStock = p.isOutOfStock;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/shop/product/${p.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Container(
                      color: const Color(0xFFF1F5F9),
                      child: p.imageUrl.isNotEmpty
                          ? AnimatedScale(
                              scale: _hovered ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              child: Image.network(
                                p.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                cacheWidth: 320,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Text('\uD83D\uDCF1', style: TextStyle(fontSize: 28)),
                                ),
                              ),
                            )
                          : const Center(
                              child: Text('\uD83D\uDCF1', style: TextStyle(fontSize: 28)),
                            ),
                    ),
                    if (discount > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    if (outOfStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\u20B9${p.effectivePrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                            height: 1.0,
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '\u20B9${p.price.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

/// Timer badge
class _TimerBadge extends StatelessWidget {
  final Duration timeLeft;
  const _TimerBadge({required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final h = timeLeft.inHours.toString().padLeft(2, '0');
    final m = (timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final s = (timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$h:$m:$s',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
