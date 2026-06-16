import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/product_provider.dart';

/// Flipkart-style left sidebar filter panel for desktop/tablet.
class FilterSidebarPanel extends StatelessWidget {
  const FilterSidebarPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Container(
      width: 260,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.6)),
      ),
      child: Column(
        children: [
          // Header: FILTERS + CLEAR ALL
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FILTERS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 1.5,
                  ),
                ),
                if (provider.hasActiveFilters)
                  GestureDetector(
                    onTap: () => provider.clearAllFilters(),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1400E0),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Scrollable filter sections
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // CATEGORIES section (single-select; web parity). Shown global,
                // so the shopper can switch category from inside the filter.
                if (provider.availableCategories.isNotEmpty)
                  _FilterSection(
                    title: 'CATEGORIES',
                    child: _CategoryFilterSection(provider: provider),
                  ),

                // PRICE section
                _FilterSection(
                  title: 'PRICE',
                  child: _PriceFilterSection(provider: provider),
                ),

                // BRAND section (shown when browsing a category or all)
                if (provider.availableBrands.isNotEmpty)
                  _FilterSection(
                    title: 'BRAND',
                    child: _BrandFilterSection(provider: provider),
                  ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible filter section with title and divider.
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x66E2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF334155),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          child,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Price range checkboxes (Flipkart style).
class _PriceFilterSection extends StatelessWidget {
  final ProductProvider provider;

  const _PriceFilterSection({required this.provider});

  static const _priceRanges = [
    (label: 'Under \u20B95,000', min: 0.0, max: 5000.0),
    (label: '\u20B95,000 - \u20B910,000', min: 5000.0, max: 10000.0),
    (label: '\u20B910,000 - \u20B915,000', min: 10000.0, max: 15000.0),
    (label: '\u20B915,000 - \u20B920,000', min: 15000.0, max: 20000.0),
    (label: '\u20B920,000 - \u20B930,000', min: 20000.0, max: 30000.0),
    (label: '\u20B930,000 - \u20B950,000', min: 30000.0, max: 50000.0),
    (label: '\u20B950,000 - \u20B91,00,000', min: 50000.0, max: 100000.0),
    (label: 'Above \u20B91,00,000', min: 100000.0, max: 200000.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _priceRanges.map((range) {
        final isSelected = provider.minPrice == range.min &&
            provider.maxPrice == range.max;
        return _FilterCheckbox(
          label: range.label,
          isSelected: isSelected,
          onTap: () {
            if (isSelected) {
              provider.setPriceRange(0, 200000);
            } else {
              provider.setPriceRange(range.min, range.max);
            }
          },
        );
      }).toList(),
    );
  }
}

/// Single-select category list. Selecting one reloads the listing for that
/// category (and rescopes the brand facet). "All Categories" clears it.
class _CategoryFilterSection extends StatelessWidget {
  final ProductProvider provider;

  const _CategoryFilterSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final current = (provider.filterCategory ?? '').toLowerCase();
    return Column(
      children: [
        _FilterCheckbox(
          label: 'All Categories',
          isSelected: current.isEmpty,
          onTap: () => provider.setFilterCategory(null),
        ),
        ...provider.availableCategories.map((cat) {
          return _FilterCheckbox(
            label: cat,
            isSelected: current == cat.toLowerCase(),
            onTap: () => provider.setFilterCategory(cat),
          );
        }),
      ],
    );
  }
}

/// Dynamic brand checkbox list.
class _BrandFilterSection extends StatelessWidget {
  final ProductProvider provider;

  const _BrandFilterSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: provider.availableBrands.map((brand) {
        final isSelected = provider.selectedFilterBrands.contains(brand);
        return _FilterCheckbox(
          label: brand,
          isSelected: isSelected,
          onTap: () => provider.toggleBrandFilter(brand),
        );
      }).toList(),
    );
  }
}

/// Reusable checkbox row for filter items.
class _FilterCheckbox extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterCheckbox({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primaryLight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.textTertiary,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
