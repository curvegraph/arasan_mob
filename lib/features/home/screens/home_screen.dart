import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/homepage_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/banner_section.dart';
import '../widgets/single_banner_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/deals_section.dart';
import '../widgets/recently_viewed_section.dart';
import '../widgets/brands_section.dart';
import '../widgets/products_grid_section.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledOnce = false;
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // Subscribe to real-time updates for instant homepage sync
      context.read<HomepageProvider>().subscribeToRealtimeUpdates();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool _isLoadingMore = false;

  void _onScroll() {
    final pixels = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;

    if (pixels > 200) {
      _hasScrolledOnce = true;
    }

    // Debounce: only check every 100ms to reduce scroll interference
    if (_scrollDebounce?.isActive ?? false) return;
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      // Note: Infinite scroll is handled internally by each SliverProductsGridSection
      if (_hasScrolledOnce && !_isLoadingMore && maxExtent > 300 &&
          _scrollController.position.pixels >= maxExtent - 800) {
        // Products grid sections handle their own loading
        _isLoadingMore = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _isLoadingMore = false;
        });
      }
    });
  }

  Future<void> _loadData() async {
    final homepageProvider = context.read<HomepageProvider>();

    // Only load homepage config — sections fetch their own data independently
    if (!homepageProvider.hasData) {
      await homepageProvider.loadHomepageConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homepageProvider = context.watch<HomepageProvider>();

    // Build sections dynamically — render immediately, sections load their own data.
    // No top-level loading skeleton: an empty scroll view is shown while data
    // streams in, so the user just sees products appear without a spinner.
    final sections = homepageProvider.sections;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: () async {
          await homepageProvider.refresh();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final hPad = width >= 1280
                ? 56.0
                : width >= 1024
                    ? 40.0
                    : width >= 640
                        ? 24.0
                        : 0.0;
            return CustomScrollView(
              controller: _scrollController,
              cacheExtent: 4000,
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: sections.isNotEmpty
                      ? SliverMainAxisGroup(
                          slivers: _buildSliverSections(sections),
                        )
                      : _buildEmptyHomepage(homepageProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Loading skeleton shown while homepage sections are loading
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner placeholder
          Container(
            height: 300,
            color: const Color(0xFFE8E8E8),
          ),
          const SizedBox(height: 16),
          // Category placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (_) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(30),
                ),
              )),
            ),
          ),
          const SizedBox(height: 24),
          // Product grid placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(10, (_) => Container(
                width: 180,
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  /// Homepage body when there are NO sections to render. We show ONLY what the
  /// admin configures — no synthetic "Latest products" grid. So:
  ///  • still loading        → skeleton silhouette
  ///  • otherwise (empty OR a load that returned nothing) → a retry-able state,
  ///    so pulling/refreshing re-fetches the admin's real sections.
  Widget _buildEmptyHomepage(HomepageProvider provider) {
    if (provider.isLoading || !provider.hasData) {
      return SliverToBoxAdapter(child: _buildLoadingSkeleton());
    }
    final isError = provider.error != null;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyState(
        icon: isError ? Icons.wifi_off_rounded : Icons.storefront_outlined,
        title: isError ? "Can't reach the store" : 'Nothing here yet',
        // Wording matches the web storefront's homepage network-error state.
        subtitle: isError
            ? "We couldn't load the latest products. Please check your "
                'internet connection and try again.'
            : 'Pull down to refresh.',
        action: ElevatedButton.icon(
          onPressed: () => provider.refresh(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Build sliver sections with sticky headers and scroll animations
  List<Widget> _buildSliverSections(List sections) {
    final List<Widget> slivers = [];

    for (final section in sections) {
      switch (section.type) {
        case 'banner_carousel':
          slivers.add(SliverToBoxAdapter(
            child: RepaintBoundary(
              child: BannerSection(
                sectionKey: section.key,
                title: section.title,
                config: section.config,
              ),
            ),
          ));
          break;
        case 'single_banner':
          slivers.add(SliverToBoxAdapter(
            child: RepaintBoundary(
              child: SingleBannerSection(
                sectionKey: section.key,
                title: section.title,
                config: section.config,
              ),
            ),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'category_grid':
        case 'category_slider':
          slivers.add(SliverToBoxAdapter(
            child: RepaintBoundary(
              child: CategoriesSection(
                sectionKey: section.key,
                title: section.title,
                config: section.config,
              ),
            ),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'countdown_deals':
          slivers.add(SliverToBoxAdapter(
            child: RepaintBoundary(
              child: DealsSection(
                sectionKey: section.key,
                title: section.title,
                config: section.config,
                initialProducts: section.products,
              ),
            ),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'brand_grid':
        case 'brand_slider':
          slivers.add(SliverToBoxAdapter(
            child: RepaintBoundary(
              child: BrandsSection(
                sectionKey: section.key,
                title: section.title,
                config: section.config,
              ),
            ),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'daily_deals':
          // Daily Deals uses DealsSection for countdown timer support
          slivers.add(SliverToBoxAdapter(
            child: RepaintBoundary(
              child: DealsSection(
                sectionKey: section.key,
                title: section.title,
                config: section.config,
                initialProducts: section.products,
              ),
            ),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'product_grid':
        case 'featured_products':
        case 'new_arrivals':
        case 'best_sellers':
        case 'on_sale':
          // Use ValueKey to ensure uniqueness. Render the backend-resolved
          // products directly (admin-driven); paginated grids keep fetching.
          slivers.add(SliverProductsGridSection(
            key: ValueKey('product_grid_${section.key}_${section.type}'),
            sectionKey: section.key,
            sectionType: section.type,
            title: section.title,
            config: section.config,
            initialProducts: section.products,
          ));
          break;
        case 'recently_viewed':
          slivers.add(SliverToBoxAdapter(
            child: const RepaintBoundary(child: RecentlyViewedSection()),
          ));
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          break;
        case 'today_offers':
          // "Today's Offers" — render as its own styled deal band (like Flash /
          // Daily Deals). Dedupe on the *resolved variant* (selected_variant_id)
          // not the product id: the admin can curate two variants of the same
          // product, and the backend sends each as its own entry with distinct
          // price/image. Keying on id alone would collapse them and silently
          // drop a curated variant. Fall back to id when no variant is set.
          final seenOffer = <String>{};
          final offerProducts = section.products
              .where((p) => seenOffer.add(p.selectedVariantId ?? p.id))
              .toList();
          if (offerProducts.isNotEmpty) {
            slivers.add(SliverToBoxAdapter(
              child: RepaintBoundary(
                child: DealsSection(
                  sectionKey: section.key,
                  title: section.title,
                  config: section.config,
                  initialProducts: offerProducts,
                ),
              ),
            ));
            slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
          }
          break;
        default:
          continue;
      }
    }

    return slivers;
  }
}
