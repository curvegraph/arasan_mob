import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/homepage_config.dart';
import '../../../providers/homepage_provider.dart';

/// Shop by Category — 4-column grid with circular icons.
/// Data comes dynamically from Supabase (admin-managed categories).
/// Shows nothing when no categories exist.
class CategoriesSection extends StatelessWidget {
  final String sectionKey;
  final String? title;
  final Map<String, dynamic>? config;

  const CategoriesSection({
    super.key,
    this.sectionKey = 'categories',
    this.title,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final homepageProvider = context.watch<HomepageProvider>();
    final allCategories = homepageProvider.categories;

    // The admin curates `selected_categories` — both WHICH categories appear on
    // the homepage and their order. Show ONLY those (parity with the web). A
    // category the admin left out (e.g. Flip Cover / Back Cover) must NOT appear
    // here even though it's still active in the catalogue; previously we
    // appended every non-selected category too, which leaked disabled ones onto
    // the homepage.
    final selectedCategoryIds = (config?['selected_categories'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    List<CategoryData> categories;
    if (selectedCategoryIds != null && selectedCategoryIds.isNotEmpty) {
      categories = selectedCategoryIds
          .map((id) => allCategories.where((c) => c.id == id).firstOrNull)
          .whereType<CategoryData>()
          .toList();
      // Safety net: only if NONE of the curated ids resolve (fully stale
      // config) fall back to all categories, so the strip is never empty.
      if (categories.isEmpty) categories = allCategories;
    } else {
      categories = allCategories;
    }

    // Design config
    final layout = config?['layout'] as String? ?? 'grid';
    final columns = config?['columns'] as int? ?? 0;
    final bgColor = _hexToColor(config?['bg_color'] as String? ?? '');
    final itemShape = config?['item_shape'] as String? ?? 'circle';
    final sectionPadding = config?['section_padding'] as String? ?? 'normal';
    final vertPad = sectionPadding == 'compact' ? 8.0 : sectionPadding == 'spacious' ? 24.0 : 12.0;

    return Container(
      color: bgColor ?? AppColors.background,
      padding: EdgeInsets.symmetric(vertical: vertPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // No section title - clean look like international e-commerce sites

          if (categories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) => Padding(
                    padding: EdgeInsets.only(right: index < 3 ? 24 : 0),
                    child: _PlaceholderItem(index: index),
                  )),
                ),
              ),
            )
          else if (layout == 'slider')
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => SizedBox(
                  width: 72,
                  child: _CategoryItem(category: categories[i], index: i, shape: itemShape),
                ),
              ),
            )
          else if (layout == 'card')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCardLayout(context, categories, columns, itemShape),
            )
          else if (layout == 'list')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildListLayout(context, categories, itemShape),
            )
          else
            // No outer padding — _buildGrid handles its own padding so the
            // mobile horizontal list can use the full screen width and
            // half-peek the next tile at the edge.
            _buildGrid(context, categories, columns, itemShape),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<CategoryData> categories, int columns, String shape) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;

    if (!isWide) {
      // Mobile: size tiles so exactly 5.5 fit on screen, so the 6th peeks past
      // the right edge as a "swipe for more" hint. No take() cap — all
      // categories are reachable by horizontal scroll.
      const separator = 10.0;
      const leftPad = 12.0;
      final tileWidth = (width - leftPad - 5 * separator) / 5.5;
      return SizedBox(
        height: tileWidth + 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(leftPad, 0, 0, 0),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: separator),
          itemBuilder: (_, i) => SizedBox(
            width: tileWidth,
            child: _CategoryItem(category: categories[i], index: i, shape: shape, compact: true),
          ),
        ),
      );
    }

    final tileWidth = 120.0;
    final visible = categories.take(14).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 28,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: List.generate(visible.length, (i) => SizedBox(
          width: tileWidth,
          child: _CategoryItem(category: visible[i], index: i, shape: shape),
        )),
      ),
    );
  }

  Widget _buildCardLayout(BuildContext context, List<CategoryData> categories, int columns, String shape) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveCols = columns > 0 ? columns : (width >= 600 ? 3 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveCols,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => _CategoryCardItem(category: categories[i], index: i, shape: shape),
    );
  }

  Widget _buildListLayout(BuildContext context, List<CategoryData> categories, String shape) {
    return Column(
      children: List.generate(categories.length, (i) {
        return _CategoryListItem(category: categories[i], index: i, shape: shape);
      }),
    );
  }

  static Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try { return Color(int.parse(hex, radix: 16)); } catch (_) { return null; }
  }
}

/// Card-style category item — horizontal card with icon + name + arrow
class _CategoryCardItem extends StatelessWidget {
  final CategoryData category;
  final int index;
  final String shape;

  const _CategoryCardItem({required this.category, required this.index, this.shape = 'circle'});

  static const _bgColors = [
    Color(0xFFFFE0B2), Color(0xFFB3E5FC), Color(0xFFC8E6C9), Color(0xFFF8BBD0),
    Color(0xFFD1C4E9), Color(0xFFFFF9C4), Color(0xFFFFCCBC), Color(0xFFB2DFDB),
  ];

  static const _iconColors = [
    Color(0xFFE65100), Color(0xFF0277BD), Color(0xFF2E7D32), Color(0xFFC2185B),
    Color(0xFF512DA8), Color(0xFFF9A825), Color(0xFFBF360C), Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[index % _bgColors.length];
    final iconColor = _iconColors[index % _iconColors.length];

    return GestureDetector(
      onTap: () => context.push('/shop/products?category=${Uri.encodeComponent(category.name)}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: shape != 'circle' ? BorderRadius.circular(shape == 'rounded' ? 10 : 4) : null,
              ),
              child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(shape == 'circle' ? 20 : shape == 'rounded' ? 10 : 4),
                      child: CachedNetworkImage(imageUrl: category.imageUrl!, fit: BoxFit.cover, width: 40, height: 40,
                        errorWidget: (_, __, ___) => Icon(_getIcon(category), size: 20, color: iconColor)),
                    )
                  : Icon(_getIcon(category), size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(category.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  static IconData _getIcon(CategoryData cat) {
    switch (cat.iconName?.toLowerCase()) {
      case 'smartphone': return Icons.smartphone;
      case 'headphones': return Icons.headphones;
      case 'watch': return Icons.watch;
      case 'tablet': return Icons.tablet;
      case 'laptop': return Icons.laptop;
      default: return Icons.category;
    }
  }
}

/// List-style category item — full-width row with divider
class _CategoryListItem extends StatelessWidget {
  final CategoryData category;
  final int index;
  final String shape;

  const _CategoryListItem({required this.category, required this.index, this.shape = 'circle'});

  static const _bgColors = [
    Color(0xFFFFE0B2), Color(0xFFB3E5FC), Color(0xFFC8E6C9), Color(0xFFF8BBD0),
    Color(0xFFD1C4E9), Color(0xFFFFF9C4), Color(0xFFFFCCBC), Color(0xFFB2DFDB),
  ];
  static const _iconColors = [
    Color(0xFFE65100), Color(0xFF0277BD), Color(0xFF2E7D32), Color(0xFFC2185B),
    Color(0xFF512DA8), Color(0xFFF9A825), Color(0xFFBF360C), Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[index % _bgColors.length];
    final iconColor = _iconColors[index % _iconColors.length];

    return GestureDetector(
      onTap: () => context.push('/shop/products?category=${Uri.encodeComponent(category.name)}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: const Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: shape != 'circle' ? BorderRadius.circular(shape == 'rounded' ? 10 : 4) : null,
              ),
              child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(shape == 'circle' ? 22 : shape == 'rounded' ? 10 : 4),
                      child: CachedNetworkImage(imageUrl: category.imageUrl!, fit: BoxFit.cover, width: 44, height: 44,
                        errorWidget: (_, __, ___) => Icon(_getIcon(category), size: 22, color: iconColor)),
                    )
                  : Icon(_getIcon(category), size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Browse ${category.name}',
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

  static IconData _getIcon(CategoryData cat) {
    switch (cat.iconName?.toLowerCase()) {
      case 'smartphone': return Icons.smartphone;
      case 'headphones': return Icons.headphones;
      case 'watch': return Icons.watch;
      case 'tablet': return Icons.tablet;
      case 'laptop': return Icons.laptop;
      default: return Icons.category;
    }
  }
}

class _CategoryItem extends StatefulWidget {
  final CategoryData category;
  final int index;
  final String shape;
  final bool compact;

  const _CategoryItem({
    required this.category,
    required this.index,
    this.shape = 'circle',
    this.compact = false,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  static const List<List<Color>> _tints = [
    [Color(0xFFFCE7F3), Color(0xFFFFF1F2), Color(0xFFFCE7F3)], // pink
    [Color(0xFFEDE9FE), Color(0xFFF5F3FF), Color(0xFFFAE8FF)], // violet
    [Color(0xFFE0F2FE), Color(0xFFEFF6FF), Color(0xFFEEF2FF)], // sky
    [Color(0xFFD1FAE5), Color(0xFFECFDF5), Color(0xFFCFFAFE)], // emerald
    [Color(0xFFFEF3C7), Color(0xFFFEFCE8), Color(0xFFFFEDD5)], // amber
    [Color(0xFFFFE4E6), Color(0xFFFEF2F2), Color(0xFFFCE7F3)], // rose
    [Color(0xFFCFFAFE), Color(0xFFE0F2FE), Color(0xFFEFF6FF)], // cyan
    [Color(0xFFECFCCB), Color(0xFFF0FDF4), Color(0xFFD1FAE5)], // lime
  ];

  IconData _getIcon() {
    switch (widget.category.iconName?.toLowerCase()) {
      case 'smartphone':
        return Icons.smartphone;
      case 'phone_android':
        return Icons.phone_android;
      case 'headphones':
        return Icons.headphones;
      case 'watch':
        return Icons.watch;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'tablet':
        return Icons.tablet;
      case 'laptop':
        return Icons.laptop;
      case 'tv':
        return Icons.tv;
      case 'speaker':
        return Icons.speaker;
      case 'camera':
        return Icons.camera_alt;
      case 'gamepad':
        return Icons.gamepad;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tints[widget.index % _tints.length];
    final hasImage = widget.category.imageUrl != null && widget.category.imageUrl!.isNotEmpty;
    final sparkleAlign = widget.index % 3 == 2
        ? const Alignment(-0.6, -0.7)
        : widget.index % 2 == 0
            ? const Alignment(0.65, -0.55)
            : const Alignment(0.55, -0.65);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/shop/products?category=${Uri.encodeComponent(widget.category.name)}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..translate(0.0, _hovered ? -3.0 : 0.0)
                ..scale(_hovered ? 1.04 : 1.0),
              transformAlignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    // Rounded square (not a circle) so the full category image
                    // is visible instead of being cropped to a circle.
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: tint,
                    ),
                    border: Border.all(color: const Color(0x66E2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: _hovered
                            ? const Color(0xFF1400E0).withOpacity(0.25)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: _hovered ? 28 : 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        if (hasImage)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: CachedNetworkImage(
                              imageUrl: widget.category.imageUrl!,
                              // Whole image, no crop.
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Center(
                                child: Icon(_getIcon(),
                                    size: widget.compact ? 18 : 28,
                                    color: const Color(0xFF64748B).withOpacity(0.5)),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(_getIcon(),
                                    size: widget.compact ? 18 : 28,
                                    color: const Color(0xFF64748B).withOpacity(0.5)),
                              ),
                            ),
                            ),
                          )
                        else
                          Center(
                            child: Icon(_getIcon(),
                                size: widget.compact ? 20 : 32,
                                color: const Color(0xFF475569).withOpacity(0.65)),
                          ),
                        Align(
                          alignment: sparkleAlign,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: widget.compact ? 5 : 10),
            Text(
              widget.category.name,
              style: TextStyle(
                fontSize: widget.compact ? 10 : 13,
                fontWeight: FontWeight.w700,
                color: _hovered ? const Color(0xFF1400E0) : const Color(0xFF1A1A1A),
                letterSpacing: -0.1,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: widget.compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty placeholder circle + dashed label shown when no categories exist.
class _PlaceholderItem extends StatelessWidget {
  final int index;

  const _PlaceholderItem({required this.index});

  static const _bgColors = [
    Color(0xFFF3F4F6),
    Color(0xFFEDE9FE),
    Color(0xFFE0F2FE),
    Color(0xFFFCE7F3),
    Color(0xFFF3F4F6),
    Color(0xFFEDE9FE),
    Color(0xFFE0F2FE),
    Color(0xFFFCE7F3),
  ];

  static const _iconColors = [
    Color(0xFFD1D5DB),
    Color(0xFFC4B5FD),
    Color(0xFF7DD3FC),
    Color(0xFFF9A8D4),
    Color(0xFFD1D5DB),
    Color(0xFFC4B5FD),
    Color(0xFF7DD3FC),
    Color(0xFFF9A8D4),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _bgColors[index % _bgColors.length],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.category_outlined,
            size: 22,
            color: _iconColors[index % _iconColors.length],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
