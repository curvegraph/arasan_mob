import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product.dart';
import '../../../data/services/product_service.dart';
import '../../../shared/widgets/compact_product_card.dart';
import '../../../shared/widgets/product_card_mini.dart';

/// Sliver-based products grid for smooth scrolling in CustomScrollView
class SliverProductsGridSection extends StatefulWidget {
  final String sectionKey;
  final String sectionType;
  final String? title;
  final Map<String, dynamic>? config;

  /// Backend-resolved products for this section. When supplied (and the
  /// section isn't a paginated "show all" grid) these are rendered directly,
  /// so the mobile UI mirrors exactly what the admin configured — no Dart-side
  /// re-derivation. Null means "fall back to fetching".
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
  final ProductService _productService = ProductService();
  static const int _pageSize = 40;

  List<Product> _products = [];
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  Timer? _pollTimer;

  /// True when the admin pinned variant offers to products in this section
  /// (config.show_variant_offers + a non-empty variant_choices map). Those
  /// offers live only on the backend-resolved `initialProducts`; the paginated
  /// fetch path returns plain catalogue rows without them, so we must render
  /// the embedded list to honor the admin's choice.
  bool get _hasVariantOffers {
    if (widget.config?['show_variant_offers'] != true) return false;
    final choices = widget.config?['variant_choices'];
    return choices is Map && choices.isNotEmpty;
  }

  /// Render the embedded products as-is when the admin didn't ask for a
  /// paginated "show all" list — OR when variant offers are configured (those
  /// only exist on the embedded list). Otherwise paginated grids keep fetching
  /// so a large catalog stays fully browseable via infinite scroll.
  bool get _useEmbedded =>
      widget.initialProducts != null &&
      (widget.config?['show_pagination'] != true || _hasVariantOffers);

  @override
  void initState() {
    super.initState();
    if (_useEmbedded) {
      _products = List.of(widget.initialProducts!);
      _isLoading = false;
      _hasMore = false;
    } else {
      _loadInitialProducts();
      _subscribeToProductChanges();
    }
  }

  @override
  void didUpdateWidget(covariant SliverProductsGridSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the provider refreshes, a new resolved product list arrives — adopt
    // it so admin edits show up without a manual reload.
    if (_useEmbedded &&
        !identical(widget.initialProducts, oldWidget.initialProducts)) {
      setState(() {
        _products = List.of(widget.initialProducts!);
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  void _subscribeToProductChanges() {
    // Polling-based realtime substitute (Socket.IO bridge will replace).
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadInitialProducts();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  Future<void> _loadInitialProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _fetchProducts(0);
      debugPrint('[SliverProductsGrid] Section "${widget.title}" (${widget.sectionType}): loaded ${products.length} products');
      if (mounted) {
        setState(() {
          _products = products;
          _currentPage = 0;
          _hasMore = products.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SliverProductsGrid] Error loading products for "${widget.title}": $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load products';
          _isLoading = false;
        });
      }
    }
  }

  /// Public method to load more products (called from parent via GlobalKey)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final products = await _fetchProducts(_currentPage + 1);
      if (mounted) {
        setState(() {
          _products.addAll(products);
          _currentPage++;
          _hasMore = products.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<List<Product>> _fetchProducts(int page) async {
    final productSource = widget.config?['product_source'] as String?;
    final effectiveType = productSource ?? widget.sectionType;
    final filterCategory = widget.config?['filter_category'] as String?;
    final filterBrand = widget.config?['filter_brand'] as String?;
    final daysFilter = widget.config?['days_filter'] as int? ?? 30;
    final minDiscount = (widget.config?['min_discount'] as num?)?.toDouble() ?? 0;

    // Check for manual selection (selected_product_ids)
    final selectedProductIds = widget.config?['selected_product_ids'];
    List<String>? productIds;
    if (selectedProductIds is List && selectedProductIds.isNotEmpty) {
      productIds = selectedProductIds.map((e) => e.toString()).toList();
    }

    // A "manual" section with no products selected must render nothing.
    // Otherwise it falls through to the generic "all products" query below
    // and shows the exact same list as the Product Grid (products appear twice).
    if (productSource == 'manual' && (productIds == null || productIds.isEmpty)) {
      return [];
    }

    // Verbose per-section fetch logging — only enable when diagnosing
    // homepage_sections config. Stays noisy otherwise (one block per section
    // per refresh).
    // ignore: dead_code
    const verbose = false;
    if (verbose) {
      debugPrint('[SliverProductsGrid] _fetchProducts for "${widget.title}" (${widget.sectionType}):');
      debugPrint('  - productSource: $productSource');
      debugPrint('  - effectiveType: $effectiveType');
      debugPrint('  - filterCategory: $filterCategory');
      debugPrint('  - filterBrand: $filterBrand');
      debugPrint('  - daysFilter: $daysFilter');
      debugPrint('  - minDiscount: $minDiscount');
      debugPrint('  - selectedProductIds: ${productIds?.length ?? 0} products');
    }

    // If manual selection with product IDs, fetch those specific products
    if (productIds != null && productIds.isNotEmpty) {
      // For manual selection, all products on first page, no pagination
      if (page == 0) {
        return await _productService.getProductsByIds(productIds);
      }
      return []; // No more pages for manual selection
    }

    String sortColumn = 'display_order';
    bool ascending = true;
    bool isFeatured = false;
    bool isOnSale = false;
    bool isNewArrivals = false;

    switch (effectiveType) {
      case 'new':
      case 'new_arrivals':
        isNewArrivals = true;
        break;
      case 'best_selling':
      case 'best_sellers':
        sortColumn = 'rating';
        ascending = false;
        break;
      case 'featured':
      case 'featured_products':
        isFeatured = true;
        sortColumn = 'display_order';
        ascending = true;
        break;
      case 'on_sale':
      case 'daily_deals':
      case 'Products On Sale':
        isOnSale = true;
        sortColumn = 'created_at';
        ascending = false;
        break;
      case 'product_grid':
      case 'all':
      case 'all_products':
      default:
        sortColumn = 'display_order';
        ascending = true;
        break;
    }

    // New Arrivals with date filter
    if (isNewArrivals) {
      return await _productService.getNewArrivalsPaginated(
        category: filterCategory,
        brand: filterBrand,
        daysFilter: daysFilter,
        page: page,
        pageSize: _pageSize,
      );
    }

    if (isFeatured) {
      return await _productService.getFeaturedProductsPaginated(
        category: filterCategory,
        brand: filterBrand,
        page: page,
        pageSize: _pageSize,
      );
    }

    if (isOnSale) {
      return await _productService.getOnSaleProductsPaginated(
        category: filterCategory,
        brand: filterBrand,
        page: page,
        pageSize: _pageSize,
      );
    }

    return await _productService.getFilteredProductsPaginated(
      category: filterCategory,
      brand: filterBrand,
      minDiscount: minDiscount > 0 ? minDiscount : null,
      page: page,
      pageSize: _pageSize,
      sortColumn: sortColumn,
      ascending: ascending,
    );
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

  /// Shimmer skeleton grid shown while products are loading
  Widget _buildSkeletonGrid(int crossAxisCount, {int? count}) {
    final itemCount = count ?? crossAxisCount * 3;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: _getChildAspectRatio(crossAxisCount),
          crossAxisSpacing: 12,
          mainAxisSpacing: 4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _ProductSkeletonCard(),
          childCount: itemCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _getCrossAxisCount(width);

    if (_isLoading) {
      // No skeleton — section just stays empty until products land.
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadInitialProducts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Pad the last partial row with skeleton tiles while the next page loads,
    // so loading cards fill the empty slots instead of starting a new row
    // below a half-filled one.
    // No load-more skeleton fillers — page just extends with real products
    // once the next batch resolves.
    final totalCount = _products.length;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: _getChildAspectRatio(crossAxisCount),
              crossAxisSpacing: 12,
              mainAxisSpacing: 4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _products.length) {
                  return ProductCardMini(
                    key: ValueKey('${widget.sectionKey}_${_products[index].id}_$index'),
                    product: _products[index],
                  );
                }
                return const _ProductSkeletonCard();
              },
              childCount: totalCount,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Products grid section — returns slivers for lazy rendering inside CustomScrollView
class ProductsGridSection extends StatefulWidget {
  final String sectionKey;
  final String sectionType;
  final String? title;
  final Map<String, dynamic>? config;

  const ProductsGridSection({
    super.key,
    required this.sectionKey,
    required this.sectionType,
    this.title,
    this.config,
  });

  @override
  ProductsGridSectionState createState() => ProductsGridSectionState();
}

class ProductsGridSectionState extends State<ProductsGridSection> {
  final ProductService _productService = ProductService();
  static const int _pageSize = 10;

  List<Product> _products = [];
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadInitialProducts();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  Future<void> _loadInitialProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _fetchProducts(0);
      if (mounted) {
        setState(() {
          _products = products;
          _currentPage = 0;
          _hasMore = products.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ProductsGrid] Error loading products: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load products';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final products = await _fetchProducts(_currentPage + 1);
      if (mounted) {
        setState(() {
          _products.addAll(products);
          _currentPage++;
          _hasMore = products.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<List<Product>> _fetchProducts(int page) async {
    final productSource = widget.config?['product_source'] as String?;
    final effectiveType = productSource ?? widget.sectionType;
    final filterCategory = widget.config?['filter_category'] as String?;
    final filterBrand = widget.config?['filter_brand'] as String?;
    final daysFilter = widget.config?['days_filter'] as int? ?? 30;
    final minDiscount = (widget.config?['min_discount'] as num?)?.toDouble() ?? 0;

    // Check for manual selection (selected_product_ids)
    final selectedProductIds = widget.config?['selected_product_ids'];
    List<String>? productIds;
    if (selectedProductIds is List && selectedProductIds.isNotEmpty) {
      productIds = selectedProductIds.map((e) => e.toString()).toList();
    }

    // A "manual" section with no products selected must render nothing
    // (instead of falling back to the "all products" query, which duplicates
    // whatever the generic Product Grid already shows).
    if (productSource == 'manual' && (productIds == null || productIds.isEmpty)) {
      return [];
    }

    // If manual selection with product IDs, fetch those specific products
    if (productIds != null && productIds.isNotEmpty) {
      if (page == 0) {
        return await _productService.getProductsByIds(productIds);
      }
      return [];
    }

    String sortColumn = 'display_order';
    bool ascending = true;
    bool isFeatured = false;
    bool isOnSale = false;
    bool isNewArrivals = false;

    switch (effectiveType) {
      case 'new':
      case 'new_arrivals':
        isNewArrivals = true;
        break;
      case 'best_selling':
      case 'best_sellers':
        sortColumn = 'rating';
        ascending = false;
        break;
      case 'featured':
      case 'featured_products':
        isFeatured = true;
        sortColumn = 'display_order';
        ascending = true;
        break;
      case 'on_sale':
      case 'daily_deals':
      case 'Products On Sale':
        isOnSale = true;
        sortColumn = 'created_at';
        ascending = false;
        break;
      case 'product_grid':
      case 'all':
      case 'all_products':
      default:
        sortColumn = 'display_order';
        ascending = true;
        break;
    }

    // New Arrivals with date filter
    if (isNewArrivals) {
      return await _productService.getNewArrivalsPaginated(
        category: filterCategory,
        brand: filterBrand,
        daysFilter: daysFilter,
        page: page,
        pageSize: _pageSize,
      );
    }

    // Use featured products method if needed
    if (isFeatured) {
      return await _productService.getFeaturedProductsPaginated(
        category: filterCategory,
        brand: filterBrand,
        page: page,
        pageSize: _pageSize,
      );
    }

    // Use on-sale products method if needed
    if (isOnSale) {
      return await _productService.getOnSaleProductsPaginated(
        category: filterCategory,
        brand: filterBrand,
        page: page,
        pageSize: _pageSize,
      );
    }

    // Use filtered paginated method for other cases
    return await _productService.getFilteredProductsPaginated(
      category: filterCategory,
      brand: filterBrand,
      minDiscount: minDiscount > 0 ? minDiscount : null,
      page: page,
      pageSize: _pageSize,
      sortColumn: sortColumn,
      ascending: ascending,
    );
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _getChildAspectRatio(int crossAxisCount) {
    if (crossAxisCount >= 4) return 0.66;
    if (crossAxisCount == 3) return 0.64;
    return 0.62;
  }

  /// Shimmer skeleton grid shown while products are loading
  Widget _buildSkeletonGrid(int crossAxisCount, {int? count}) {
    final itemCount = count ?? crossAxisCount * 3;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: _getChildAspectRatio(crossAxisCount),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _ProductSkeletonCard(),
          childCount: itemCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _getCrossAxisCount(width);

    if (_isLoading) {
      // No skeleton — section just stays empty until products land.
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadInitialProducts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Pad the last partial row with skeleton tiles while the next page loads,
    // so loading cards fill the empty slots instead of starting a new row
    // below a half-filled one.
    // No load-more skeleton fillers — page just extends with real products
    // once the next batch resolves.
    final totalCount = _products.length;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: _getChildAspectRatio(crossAxisCount),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _products.length) {
                  return ProductCardMini(
                    key: ValueKey('${widget.sectionKey}_${_products[index].id}_$index'),
                    product: _products[index],
                  );
                }
                return const _ProductSkeletonCard();
              },
              childCount: totalCount,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer skeleton card that mimics a product card layout
class _ProductSkeletonCard extends StatelessWidget {
  const _ProductSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      period: const Duration(milliseconds: 1200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            // Text placeholders
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  Container(
                    height: 8,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Name line 1
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Name line 2
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Container(
                    height: 14,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(6),
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
    );
  }
}
