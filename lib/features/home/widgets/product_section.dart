import 'package:flutter/material.dart';
import '../../../data/models/home_section.dart';
import '../../../data/models/product.dart';
import 'compact_product_card.dart';

/// Reusable product section widget with various layouts
class ProductSection extends StatelessWidget {
  final HomeSection section;
  final Function(Product) onProductTap;
  final VoidCallback? onViewAllTap;

  const ProductSection({
    super.key,
    required this.section,
    required this.onProductTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.hasProducts) return const SizedBox.shrink();

    return Container(
      color: section.showBackground
          ? Color(int.parse(section.backgroundColor ?? 'FFFFFFFF', radix: 16))
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(context),
          // Products layout
          _buildProductsLayout(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    if (section.showTimer && section.timerEndTime != null) ...[
                      const SizedBox(width: 10),
                      _SectionTimer(endTime: section.timerEndTime!),
                    ],
                  ],
                ),
                if (section.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (section.showViewAll && onViewAllTap != null)
            TextButton(
              onPressed: onViewAllTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsLayout(BuildContext context) {
    switch (section.layoutType) {
      case SectionLayoutType.singleSpotlight:
        return _buildSpotlightLayout(context);
      case SectionLayoutType.grid:
        return _buildGridLayout(context);
      case SectionLayoutType.carousel:
      default:
        return _buildCarouselLayout(context);
    }
  }

  Widget _buildCarouselLayout(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: section.products.length,
        itemBuilder: (context, index) {
          final product = section.products[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CompactProductCard(
              product: product,
              onTap: () => onProductTap(product),
              width: 140,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: section.products.length,
        itemBuilder: (context, index) {
          final product = section.products[index];
          return CompactProductCard(
            product: product,
            onTap: () => onProductTap(product),
            width: double.infinity,
          );
        },
      ),
    );
  }

  Widget _buildSpotlightLayout(BuildContext context) {
    if (section.products.isEmpty) return const SizedBox.shrink();
    final product = section.products.first;

    return SpotlightProductCard(
      product: product,
      onTap: () => onProductTap(product),
      timerEndTime: section.timerEndTime,
    );
  }
}

class _SectionTimer extends StatefulWidget {
  final DateTime endTime;

  const _SectionTimer({required this.endTime});

  @override
  State<_SectionTimer> createState() => _SectionTimerState();
}

class _SectionTimerState extends State<_SectionTimer> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _startTimer();
  }

  void _calculateRemaining() {
    _remaining = widget.endTime.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _calculateRemaining();
      });
      return _remaining > Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flash Deals Section with enhanced timer
class FlashDealsSection extends StatelessWidget {
  final HomeSection section;
  final Function(Product) onProductTap;
  final VoidCallback? onViewAllTap;

  const FlashDealsSection({
    super.key,
    required this.section,
    required this.onProductTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.hasProducts) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B).withValues(alpha:0.1),
            const Color(0xFFFF8E53).withValues(alpha:0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with lightning bolt
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flash Deals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        'Hurry! Limited time offers',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (section.timerEndTime != null)
                  _SectionTimer(endTime: section.timerEndTime!),
                const SizedBox(width: 8),
                if (onViewAllTap != null)
                  IconButton(
                    onPressed: onViewAllTap,
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          // Products carousel
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: section.products.length,
              itemBuilder: (context, index) {
                final product = section.products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CompactProductCard(
                    product: product,
                    onTap: () => onProductTap(product),
                    width: 140,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Best Selling / Popular Section
class BestSellingSection extends StatelessWidget {
  final HomeSection section;
  final Function(Product) onProductTap;
  final VoidCallback? onViewAllTap;

  const BestSellingSection({
    super.key,
    required this.section,
    required this.onProductTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.hasProducts) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with trophy icon
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best Selling',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Text(
                      'Our most popular products',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (onViewAllTap != null)
                TextButton(
                  onPressed: onViewAllTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Products carousel
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: section.products.length,
            itemBuilder: (context, index) {
              final product = section.products[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    CompactProductCard(
                      product: product,
                      onTap: () => onProductTap(product),
                      width: 140,
                    ),
                    // Rank badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: index < 3 ? const Color(0xFFFFD700) : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// New Arrivals Section with NEW badge
class NewArrivalsSection extends StatelessWidget {
  final HomeSection section;
  final Function(Product) onProductTap;
  final VoidCallback? onViewAllTap;

  const NewArrivalsSection({
    super.key,
    required this.section,
    required this.onProductTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.hasProducts) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withValues(alpha:0.05),
            const Color(0xFF764BA2).withValues(alpha:0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.new_releases,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Arrivals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        'Just landed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onViewAllTap != null)
                  TextButton(
                    onPressed: onViewAllTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Products carousel with NEW badge
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: section.products.length,
              itemBuilder: (context, index) {
                final product = section.products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      CompactProductCard(
                        product: product,
                        onTap: () => onProductTap(product),
                        width: 140,
                      ),
                      // NEW badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Top Rated Section
class TopRatedSection extends StatelessWidget {
  final HomeSection section;
  final Function(Product) onProductTap;
  final VoidCallback? onViewAllTap;

  const TopRatedSection({
    super.key,
    required this.section,
    required this.onProductTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.hasProducts) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF388E3C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Rated',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Text(
                      'Highly rated by customers',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (onViewAllTap != null)
                TextButton(
                  onPressed: onViewAllTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Products carousel
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: section.products.length,
            itemBuilder: (context, index) {
              final product = section.products[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CompactProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                  width: 140,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Recently Viewed Section
class RecentlyViewedSection extends StatelessWidget {
  final HomeSection section;
  final Function(Product) onProductTap;
  final VoidCallback? onClearHistory;

  const RecentlyViewedSection({
    super.key,
    required this.section,
    required this.onProductTap,
    this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.hasProducts) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recently Viewed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                if (onClearHistory != null)
                  TextButton(
                    onPressed: onClearHistory,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Products carousel
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: section.products.length,
              itemBuilder: (context, index) {
                final product = section.products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CompactProductCard(
                    product: product,
                    onTap: () => onProductTap(product),
                    width: 140,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
