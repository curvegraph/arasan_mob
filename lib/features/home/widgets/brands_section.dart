import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/homepage_config.dart';
import '../../../providers/homepage_provider.dart';

/// Shop by Brand section with dynamic data
class BrandsSection extends StatelessWidget {
  final String sectionKey;
  final String? title;
  final Map<String, dynamic>? config;

  const BrandsSection({
    super.key,
    this.sectionKey = 'brands',
    this.title,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final homepageProvider = context.watch<HomepageProvider>();
    final allBrands = homepageProvider.brands;
    final maxItems = (config?['max_items'] as num?)?.toInt();

    // Filter by selected brands if specified in config
    final selectedBrandIds = (config?['selected_brands'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    List<BrandData> brands;
    if (selectedBrandIds != null && selectedBrandIds.isNotEmpty) {
      // Show only selected brands in the order they were selected
      final selected = selectedBrandIds
          .map((id) => allBrands.where((b) => b.id == id).firstOrNull)
          .whereType<BrandData>()
          .toList();
      brands = maxItems != null ? selected.take(maxItems).toList() : selected;
    } else {
      // Show all brands (capped only when admin set an explicit max)
      brands = maxItems != null
          ? allBrands.take(maxItems).toList()
          : allBrands;
    }

    if (brands.isEmpty) return const SizedBox.shrink();

    // Design config
    final layout = config?['layout'] as String? ?? 'slider';
    final columns = config?['columns'] as int? ?? 0;
    final bgColor = _hexToColor(config?['bg_color'] as String? ?? '');
    final sectionPadding = config?['section_padding'] as String? ?? 'normal';
    final vertPad = sectionPadding == 'compact' ? 8.0 : sectionPadding == 'spacious' ? 24.0 : 16.0;

    final bg = bgColor;
    Widget body;
    if (layout == 'grid') {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildGrid(context, brands, columns),
      );
    } else if (layout == 'card') {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildCardLayout(context, brands, columns),
      );
    } else if (layout == 'list') {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildListLayout(brands),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _BrandTrustStage(brands: brands),
      );
    }

    return Container(
      color: bg ?? AppColors.surface,
      padding: EdgeInsets.symmetric(vertical: vertPad),
      child: body,
    );
  }

  Widget _buildGrid(BuildContext context, List<BrandData> brands, int columns) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveCols = columns > 0 ? columns : (width >= 600 ? 5 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveCols,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: brands.length,
      itemBuilder: (_, i) => _BrandCard(brand: brands[i], index: i),
    );
  }

  Widget _buildCardLayout(BuildContext context, List<BrandData> brands, int columns) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveCols = columns > 0 ? columns : (width >= 600 ? 3 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveCols,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: brands.length,
      itemBuilder: (_, i) => _BrandCardItem(brand: brands[i], index: i),
    );
  }

  Widget _buildListLayout(List<BrandData> brands) {
    return Column(
      children: List.generate(brands.length, (i) => _BrandListItem(brand: brands[i], index: i)),
    );
  }

  static Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try { return Color(int.parse(hex, radix: 16)); } catch (_) { return null; }
  }
}

/// Card-style brand — horizontal card with logo + name + arrow
class _BrandCardItem extends StatelessWidget {
  final BrandData brand;
  final int index;
  const _BrandCardItem({required this.brand, required this.index});

  static const _bgColors = [
    Color(0xFFF5F5F7), Color(0xFFE8F4FD), Color(0xFFFFF0F0), Color(0xFFFFF5E6),
    Color(0xFFE6F2FF), Color(0xFFE8F8E8), Color(0xFFFFF8E1), Color(0xFFF1F3F4),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[index % _bgColors.length];
    return GestureDetector(
      // Filter by brand NAME (matches the value stored in products.brand);
      // the slug is URL-friendly but products aren't joined by slug.
      onTap: () => context.push(
        '/shop/products?brand=${Uri.encodeQueryComponent(brand.name)}',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: brand.logoUrl!, fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => _BrandInitial(name: brand.name)),
                    )
                  : _BrandInitial(name: brand.name),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(brand.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// List-style brand — full-width row with divider
class _BrandListItem extends StatelessWidget {
  final BrandData brand;
  final int index;
  const _BrandListItem({required this.brand, required this.index});

  static const _bgColors = [
    Color(0xFFF5F5F7), Color(0xFFE8F4FD), Color(0xFFFFF0F0), Color(0xFFFFF5E6),
    Color(0xFFE6F2FF), Color(0xFFE8F8E8), Color(0xFFFFF8E1), Color(0xFFF1F3F4),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[index % _bgColors.length];
    return GestureDetector(
      // Filter by brand NAME (matches the value stored in products.brand);
      // the slug is URL-friendly but products aren't joined by slug.
      onTap: () => context.push(
        '/shop/products?brand=${Uri.encodeQueryComponent(brand.name)}',
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(imageUrl: brand.logoUrl!, fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => _BrandInitial(name: brand.name)),
                    )
                  : _BrandInitial(name: brand.name),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Explore ${brand.name} products',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// Single brand card
class _BrandCard extends StatelessWidget {
  final BrandData brand;
  final int index;

  const _BrandCard({
    required this.brand,
    required this.index,
  });

  // Color palette for brand card backgrounds
  static const _bgColors = [
    Color(0xFFF5F5F7), // Apple-like gray
    Color(0xFFE8F4FD), // Samsung blue tint
    Color(0xFFFFF0F0), // OnePlus red tint
    Color(0xFFFFF5E6), // Xiaomi orange tint
    Color(0xFFE6F2FF), // Vivo blue tint
    Color(0xFFE8F8E8), // Oppo green tint
    Color(0xFFFFF8E1), // Realme yellow tint
    Color(0xFFF1F3F4), // Google gray
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[index % _bgColors.length];

    return RepaintBoundary(
      child: GestureDetector(
      onTap: () {
        // Filter by brand NAME — products.brand stores the name, not slug.
        context.push(
          '/shop/products?brand=${Uri.encodeQueryComponent(brand.name)}',
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final logoSize = (w * 0.45).clamp(28.0, 48.0);
          final fontSize = (w * 0.13).clamp(10.0, 13.0);

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: brand.logoUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => _BrandInitial(name: brand.name),
                                  errorWidget: (_, __, ___) =>
                                      _BrandInitial(name: brand.name),
                                ),
                              )
                            : _BrandInitial(name: brand.name),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          brand.name,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Animated diagonal shine sweep
                  IgnorePointer(
                    child: _ShineSweep(staggerMs: (index * 250) % 2500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

/// Diagonal shine overlay — a slim white gradient band slides across the card
/// during a short sweep window, then rests until the next cycle.
class _ShineSweep extends StatefulWidget {
  final int staggerMs;
  const _ShineSweep({this.staggerMs = 0});

  @override
  State<_ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<_ShineSweep>
    with SingleTickerProviderStateMixin {
  static const int _maxCycles = 4;
  late final AnimationController _ctrl;
  int _cyclesDone = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..addStatusListener(_onStatus);
    Future.delayed(Duration(milliseconds: widget.staggerMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _cyclesDone++;
      if (_cyclesDone < _maxCycles) {
        _ctrl
          ..reset()
          ..forward();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onStatus);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          // Sweep only during the first 35% of the cycle, rest after
          if (t == 0 || t >= 0.35) return const SizedBox.shrink();
          final progress = t / 0.35; // 0..1
          return LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              final bandWidth = w * 0.35;
              // Slide the band from off-left to off-right
              final x = -bandWidth + progress * (w + bandWidth * 2);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: x,
                    top: -h,
                    width: bandWidth,
                    height: h * 3,
                    child: Transform.rotate(
                      angle: -0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.55),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Auto-scrolling right-to-left brand marquee with seamless loop
class _MarqueeBrands extends StatefulWidget {
  final List<BrandData> brands;
  const _MarqueeBrands({required this.brands});

  @override
  State<_MarqueeBrands> createState() => _MarqueeBrandsState();
}

class _MarqueeBrandsState extends State<_MarqueeBrands>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 100;
  static const double _gap = 12;
  static const double _pxPerSecond = 30;

  late final AnimationController _ctrl;
  late final double _rowWidth;

  @override
  void initState() {
    super.initState();
    _rowWidth = widget.brands.length * (_cardWidth + _gap);
    final seconds = (_rowWidth / _pxPerSecond).clamp(15.0, 120.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (seconds * 1000).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.brands.length; i++) ...[
          SizedBox(
            width: _cardWidth,
            child: _BrandCard(brand: widget.brands[i], index: i),
          ),
          const SizedBox(width: _gap),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use enough copies so the row always covers the full screen width
    // while one copy is mid-exit — otherwise a gap appears during the loop
    final screenWidth = MediaQuery.sizeOf(context).width;
    final copies = ((screenWidth / _rowWidth).ceil() + 1).clamp(2, 8);

    final strip = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(copies, (_) => _buildRow()),
    );

    return RepaintBoundary(
      child: SizedBox(
        height: 90,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _ctrl,
              child: RepaintBoundary(child: strip),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-_ctrl.value * _rowWidth, 0),
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Cyan trust-pill stage with auto-scrolling brand pills (matches svelte design)
class _BrandTrustStage extends StatefulWidget {
  final List<BrandData> brands;
  const _BrandTrustStage({required this.brands});

  @override
  State<_BrandTrustStage> createState() => _BrandTrustStageState();
}

class _BrandTrustStageState extends State<_BrandTrustStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hovered = false;

  static const _glowColors = [
    Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFA855F7), Color(0xFF06B6D4), Color(0xFF84CC16), Color(0xFFF43F5E),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loop = [...widget.brands, ...widget.brands];

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.stop();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.repeat();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 92,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFFDBEAFE)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    return LayoutBuilder(
                      builder: (context, c) {
                        final pillStrip = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < loop.length; i++) ...[
                              _BrandTrustPill(
                                brand: loop[i],
                                glow: _glowColors[
                                    (i % widget.brands.length) % _glowColors.length],
                              ),
                              const SizedBox(width: 12),
                            ],
                          ],
                        );

                        return OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: double.infinity,
                          child: Transform.translate(
                            offset: Offset(-_ctrl.value * c.maxWidth, 0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              child: pillStrip,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 64,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFE0F2FE), Color(0x00E0F2FE)],
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 64,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Color(0xFFE0F2FE), Color(0x00E0F2FE)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandTrustPill extends StatefulWidget {
  final BrandData brand;
  final Color glow;
  const _BrandTrustPill({required this.brand, required this.glow});

  @override
  State<_BrandTrustPill> createState() => _BrandTrustPillState();
}

class _BrandTrustPillState extends State<_BrandTrustPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.brand.logoUrl != null && widget.brand.logoUrl!.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(
          '/shop/products?brand=${Uri.encodeQueryComponent(widget.brand.name)}',
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
          padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF7DD3FC)),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.glow.withOpacity(0.45)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _hovered ? 20 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF16A34A), Color(0xFF10B981)],
                  ),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 13),
              ),
              const SizedBox(width: 8),
              if (hasLogo)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 22, maxWidth: 64),
                  child: CachedNetworkImage(
                    imageUrl: widget.brand.logoUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Text(
                      widget.brand.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  widget.brand.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand initial letter widget
class _BrandInitial extends StatelessWidget {
  final String name;

  const _BrandInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
