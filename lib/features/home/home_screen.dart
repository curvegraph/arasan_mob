import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/homepage_provider.dart';
import '../../providers/search_provider.dart';
import 'widgets/banner_section.dart';
import 'widgets/single_banner_section.dart';
import 'widgets/categories_section.dart';
import 'widgets/deals_section.dart';
import 'widgets/recently_viewed_section.dart';
import 'widgets/brands_section.dart';
import 'widgets/products_grid_section.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ProductsGridSectionState> _productsGridKey = GlobalKey();
  bool _hasScrolledOnce = false;
  // Cache slivers so flutter_animate entry effects don't replay on every
  // parent rebuild (search/refresh/provider notifications).
  List? _cachedSectionsRef;
  List<Widget>? _cachedSlivers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pixels = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;

    if (pixels > 200) {
      _hasScrolledOnce = true;
    }

    if (_hasScrolledOnce && maxExtent > 500 && pixels >= maxExtent - 500) {
      _productsGridKey.currentState?.loadMoreProducts();
    }
  }

  Future<void> _loadData() async {
    final homepageProvider = context.read<HomepageProvider>();

    // Only load homepage config — sections fetch their own data
    if (!homepageProvider.hasData) {
      await homepageProvider.loadHomepageConfig();
    }
  }

  Future<void> _onRefresh() async {
    final homepageProvider = context.read<HomepageProvider>();
    await homepageProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final homepageProvider = context.watch<HomepageProvider>();

    // Only wait for homepage config (the layout blueprint)
    if (homepageProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryLight,
            strokeWidth: 3,
          ),
        ),
      );
    }

    final sections = homepageProvider.sections;
    final searchProvider = context.watch<SearchProvider>();
    final isSearchActive = searchProvider.query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        displacement: 60,
        strokeWidth: 2.5,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          // Keep ~1.5 viewports of widgets alive above/below the visible area
          // so scrolling back doesn't tear down + rebuild image widgets and
          // re-trigger decoding.
          cacheExtent: 1500,
          slivers: [
            if (isSearchActive)
              SliverToBoxAdapter(child: _buildSearchResults(searchProvider))
            else
              ..._sliversFor(sections),
          ],
        ),
      ),
    );
  }

  /// Build inline search results on the home page
  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
    }

    final results = searchProvider.results;

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'No products found for "${searchProvider.query}"',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try a different search term',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              '${results.length} result${results.length == 1 ? '' : 's'} for "${searchProvider.query}"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final product = results[index];
              final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.surfaceVariant,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.smartphone, color: AppColors.textTertiary),
                          )
                        : const Icon(Icons.smartphone, color: AppColors.textTertiary),
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '\u20B9${product.effectivePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                onTap: () => context.push('/shop/product/${product.id}'),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Cached wrapper — only rebuilds slivers when the sections list reference
  /// changes. Prevents flutter_animate entry effects from replaying on every
  /// parent rebuild (search input, refresh, etc.).
  List<Widget> _sliversFor(List sections) {
    if (identical(_cachedSectionsRef, sections) && _cachedSlivers != null) {
      return _cachedSlivers!;
    }
    _cachedSectionsRef = sections;
    _cachedSlivers = _buildSliverSections(sections);
    return _cachedSlivers!;
  }

  /// Build sliver sections — with sticky headers and animations
  List<Widget> _buildSliverSections(List sections) {
    final List<Widget> slivers = [];

    for (final section in sections) {
      switch (section.type) {
        case 'banner_carousel':
          slivers.add(SliverToBoxAdapter(
            child: BannerSection(
              sectionKey: section.key,
              title: section.title,
              config: section.config,
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.03, end: 0, duration: 500.ms, curve: Curves.easeOut),
          ));
          break;
        case 'single_banner':
          slivers.add(SliverToBoxAdapter(
            child: SingleBannerSection(
              sectionKey: section.key,
              title: section.title,
              config: section.config,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideX(begin: 0.02, end: 0, duration: 400.ms, curve: Curves.easeOut),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'category_grid':
          // Sticky header for categories
          slivers.add(
            SliverStickyHeader(
              header: _StickyHeaderBar(
                title: section.title ?? 'Shop by Category',
                icon: Icons.category_outlined,
              ),
              sliver: SliverToBoxAdapter(
                child: CategoriesSection(
                  sectionKey: section.key,
                  title: section.title,
                  config: section.config,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 150.ms)
                    .slideY(begin: 0.03, end: 0, duration: 400.ms, curve: Curves.easeOut),
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'countdown_deals':
          slivers.add(SliverToBoxAdapter(
            child: DealsSection(
              sectionKey: section.key,
              title: section.title,
              config: section.config,
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOut),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'brand_grid':
          slivers.add(
            SliverStickyHeader(
              header: _StickyHeaderBar(
                title: section.title ?? 'Shop by Brand',
                icon: Icons.storefront_outlined,
              ),
              sliver: SliverToBoxAdapter(
                child: BrandsSection(
                  sectionKey: section.key,
                  title: section.title,
                  config: section.config,
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 150.ms)
                    .slideY(begin: 0.03, end: 0, duration: 400.ms, curve: Curves.easeOut),
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'product_grid':
        case 'featured_products':
        case 'new_arrivals':
        case 'best_sellers':
          // Sticky header for product grids
          final gridTitle = section.title ??
              (section.type == 'featured_products'
                  ? 'Featured Products'
                  : section.type == 'new_arrivals'
                      ? 'New Arrivals'
                      : section.type == 'best_sellers'
                          ? 'Best Sellers'
                          : 'All Products');
          final gridIcon = section.type == 'featured_products'
              ? Icons.star_outline
              : section.type == 'new_arrivals'
                  ? Icons.fiber_new_outlined
                  : section.type == 'best_sellers'
                      ? Icons.trending_up
                      : Icons.grid_view_outlined;

          slivers.add(
            SliverStickyHeader(
              header: _StickyHeaderBar(
                title: gridTitle,
                icon: gridIcon,
              ),
              sliver: ProductsGridSection(
                key: _productsGridKey,
                sectionKey: section.key,
                sectionType: section.type,
                title: section.title,
                config: section.config,
              ),
            ),
          );
          break;
        case 'recently_viewed':
          slivers.add(SliverToBoxAdapter(
            child: const RecentlyViewedSection()
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        default:
          continue;
      }
    }

    return slivers;
  }
}

/// Sticky section header bar — sticks to top while scrolling through section
class _StickyHeaderBar extends StatelessWidget {
  final String title;
  final IconData icon;

  const _StickyHeaderBar({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
