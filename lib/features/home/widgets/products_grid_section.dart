import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card_mini.dart';

/// Sliver-based products grid for smooth scrolling in CustomScrollView.
///
/// Pure renderer of the backend-resolved product list. Every admin convention
/// (curated ids, `product_source`, sort-by-behavior, `min_discount`, deal
/// "discounted-only", `show_pagination` "show all", variant offers) is resolved
/// server-side in `homepage.controller.js resolveSectionProducts` — the SAME
/// resolver the web storefront's `+page.server.ts` calls — so the mobile UI
/// mirrors exactly what the admin configured. There is NO Dart-side
/// re-derivation or refetching: the HomepageProvider's poll / realtime refresh
/// hands us a fresh `initialProducts` list and we adopt it.
class SliverProductsGridSection extends StatefulWidget {
  final String sectionKey;
  final String sectionType;
  final String? title;
  final Map<String, dynamic>? config;

  /// Backend-resolved products for this section, rendered directly.
  final List<Product>? initialProducts;

  const SliverProductsGridSection({
    super.key,
    required this.sectionKey,
    required this.sectionType,
    this.title,
    this.config,
    this.initialProducts,
  });

  @override
  SliverProductsGridSectionState createState() => SliverProductsGridSectionState();
}

class SliverProductsGridSectionState extends State<SliverProductsGridSection> {
  List<Product> _products = [];

  // Section types that get a title heading above the grid — mirrors the web
  // storefront's `section-product-grid.svelte` HEADED_TYPES. A plain
  // `product_grid` (the generic "all products" list) stays headingless on both.
  static const _headedTypes = {
    'featured_products',
    'new_arrivals',
    'best_sellers',
    'on_sale',
  };

  bool get _showHeading =>
      _headedTypes.contains(widget.sectionType) &&
      (widget.title?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _products = List.of(widget.initialProducts ?? const <Product>[]);
  }

  @override
  void didUpdateWidget(covariant SliverProductsGridSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A provider refresh (60s poll / admin realtime edit) hands us a freshly
    // resolved list — adopt it so admin changes show up without a manual reload.
    if (!identical(widget.initialProducts, oldWidget.initialProducts)) {
      setState(() {
        _products = List.of(widget.initialProducts ?? const <Product>[]);
      });
    }
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  // Mobile tiles need extra height for brand+rating, 2-line name, price,
  // savings pill, and the dual Add/Buy CTA bar. Desktop has more breathing
  // room so we keep the original ratio there.
  double _getChildAspectRatio(int crossAxisCount) {
    if (crossAxisCount >= 4) return 0.66;
    if (crossAxisCount == 3) return 0.64;
    return 0.62;
  }

  /// Title heading above the grid — a gradient accent bar + bold title (+
  /// optional subtitle from config), mirroring the web `section-header.svelte`.
  /// The home page never shows a "View all" link (web suppresses it too), so
  /// this is title-only.
  Widget _buildHeader() {
    final subtitle = (widget.config?['subtitle'] as String?)?.trim();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: subtitle != null && subtitle.isNotEmpty ? 40 : 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1400E0), Color(0xFF2962FF)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _getCrossAxisCount(width);

    // Cards carrying a variant chip (colour · storage · RAM) are one row taller.
    // Give those sections slightly taller cells so the chip card doesn't
    // overflow its tile; plain sections keep the tighter ratio.
    final hasVariantCards =
        _products.any((p) => (p.variantLabel ?? '').trim().isNotEmpty);
    final aspect =
        _getChildAspectRatio(crossAxisCount) - (hasVariantCards ? 0.05 : 0.0);

    final grid = SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspect,
          crossAxisSpacing: 12,
          mainAxisSpacing: 4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCardMini(
            key: ValueKey('${widget.sectionKey}_${_products[index].id}_$index'),
            product: _products[index],
          ),
          // Slivers build lazily, so a full "show all" list (drained server-side)
          // only materializes the cards actually on screen.
          childCount: _products.length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: true,
        ),
      ),
    );

    if (!_showHeading) return grid;

    return SliverMainAxisGroup(slivers: [_buildHeader(), grid]);
  }
}
