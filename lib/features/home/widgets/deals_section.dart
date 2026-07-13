import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product.dart';
import '../../../providers/homepage_provider.dart';
import '../../../shared/widgets/animated_product_image.dart';

/// Flash Deals section — gradient background, countdown timer, auto-scrolling carousel.
/// Fetches only the deal products it needs (not the full catalog).
class DealsSection extends StatefulWidget {
  final String sectionKey;
  final String? title;
  final Map<String, dynamic>? config;

  /// Backend-resolved deal products. When supplied they're rendered directly
  /// (mirrors the admin config); otherwise the section falls back to fetching.
  final List<Product>? initialProducts;

  const DealsSection({
    super.key,
    this.sectionKey = 'flash_deals',
    this.title,
    this.config,
    this.initialProducts,
  });

  @override
  State<DealsSection> createState() => _DealsSectionState();
}

class _DealsSectionState extends State<DealsSection> {
  late Timer _countdownTimer;
  final ValueNotifier<Duration> _timeLeftNotifier = ValueNotifier(Duration.zero);

  late final ScrollController _scrollController;
  bool _visible = true;

  // Backend-resolved deal products, rendered directly. Every caller (the home
  // screen) supplies them; the HomepageProvider refresh feeds updates through
  // didUpdateWidget — no per-section fetch/poll.
  List<Product> _dealsProducts = [];

  // Section-specific timer config
  DateTime? _endTime;
  bool _showTimer = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _parseTimerConfig();
    _startCountdown();
    _dealsProducts = List.of(widget.initialProducts ?? const <Product>[]);
  }

  @override
  void didUpdateWidget(covariant DealsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.initialProducts, oldWidget.initialProducts)) {
      setState(() {
        _dealsProducts = List.of(widget.initialProducts ?? const <Product>[]);
      });
    }
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
    super.dispose();
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
    final isToday = section?.type == 'today_offers';
    final isDaily = section?.type == 'daily_deals';
    final defaultTitle =
        isToday ? "Today's Offers" : isDaily ? 'Daily Deals' : 'Flash Deals';
    // Today's Offers is admin-curated, not a flash deal — don't borrow the
    // flash-deal title/timer for it.
    final title =
        (isToday ? section?.title : (flashDeal?.title ?? section?.title)) ??
            defaultTitle;
    final showTimer = !isToday;

    if (_dealsProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    debugPrint('[DealsSection] ${widget.sectionKey}: Building with ${_dealsProducts.length} products');

    final bandColor = isToday
        ? const Color(0xFF7C3AED) // purple for Today's Offers
        : isDaily
            ? const Color(0xFF2962FF)
            : const Color(0xFFF0593F);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;
    // Smaller deal cards on mobile so the band takes less vertical space.
    final cardWidth = isWide ? 160.0 : 96.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: isWide ? 4 : 3),
      decoration: BoxDecoration(
        color: bandColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.fromLTRB(
          isWide ? 20 : 14, isWide ? 14 : 10, isWide ? 20 : 14, isWide ? 18 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isWide ? 20 : 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (showTimer)
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
          SizedBox(height: isWide ? 12 : 8),
          SizedBox(
            // Hug the card: square image + name + price all live inside the box.
            // Enough for the sale price + struck original price + discount chip
            // to wrap to extra lines on narrow cards without overflowing the box.
            height: cardWidth + (isWide ? 90 : 80),
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
        onTap: () => context.push(
          p.selectedVariantId == null
              ? '/shop/product/${p.id}'
              : '/shop/product/${p.id}?variant=${p.selectedVariantId}',
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
          // Whole product \u2014 image + name + price \u2014 inside ONE white box, same
          // look as the brand boxes.
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14000000)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.22 : 0.12),
                blurRadius: _hovered ? 16 : 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square product image \u2014 contain + inset so the looping animation
              // has headroom and never clips the product.
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                        child: p.imageUrl.isNotEmpty
                            ? AnimatedProductImage(
                                animation: p.imageAnimation,
                                child: AnimatedScale(
                                  scale: _hovered ? 1.03 : 1.0,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  child: Image.network(
                                    p.imageUrl,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    cacheWidth: 320,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text('\uD83D\uDCF1', style: TextStyle(fontSize: 28)),
                                    ),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text('\uD83D\uDCF1', style: TextStyle(fontSize: 28)),
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
              // Name + price INSIDE the box (dark text on white).
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      runSpacing: 3,
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
                        // Original price struck through when a sale/offer applies
                        // (admin's original price vs sale price). Matches the web
                        // storefront, which shows both.
                        if (p.hasDiscount)
                          Text(
                            '\u20B9${p.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                              height: 1.0,
                            ),
                          ),
                        if (discount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$discount% OFF',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
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
    // Mirror the web flash-deals countdown: show a leading "Nd" segment for
    // multi-day deals (so a 2-day deal reads "2d 00:00:00", not "48:00:00"),
    // then roll hours back to 0–23.
    final d = timeLeft.inDays;
    final h = (timeLeft.inHours % 24).toString().padLeft(2, '0');
    final m = (timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final s = (timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    final label = d > 0 ? '${d}d $h:$m:$s' : '$h:$m:$s';

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
            label,
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
