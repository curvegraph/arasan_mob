import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/product_provider.dart';

/// Mobile bottom sheet with dynamic filters driven by ProductProvider.
class ProductFiltersSheet extends StatefulWidget {
  final ProductProvider provider;

  const ProductFiltersSheet({
    super.key,
    required this.provider,
  });

  @override
  State<ProductFiltersSheet> createState() => _ProductFiltersSheetState();

  static void show(BuildContext context, {required ProductProvider provider}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFiltersSheet(provider: provider),
    );
  }
}

class _ProductFiltersSheetState extends State<ProductFiltersSheet> {
  late Set<String> _selectedBrands;
  late double _minPrice;
  late double _maxPrice;
  late double _minRating;
  late double _minDiscount;
  late bool _inStockOnly;

  ProductProvider get _provider => widget.provider;

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
  void initState() {
    super.initState();
    _selectedBrands = Set.from(_provider.selectedFilterBrands);
    _minPrice = _provider.minPrice;
    _maxPrice = _provider.maxPrice;
    _minRating = _provider.minRating;
    _minDiscount = _provider.minDiscount;
    _inStockOnly = _provider.inStockOnly;
  }

  void _clearAll() {
    setState(() {
      _selectedBrands = {};
      _minPrice = 0;
      _maxPrice = 200000;
      _minRating = 0;
      _minDiscount = 0;
      _inStockOnly = false;
    });
  }

  void _applyFilters() {
    _provider.applyFilters(
      brands: _selectedBrands,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      minDiscount: _minDiscount,
      inStockOnly: _inStockOnly,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.glassWhite),
              left: BorderSide(color: AppColors.glassWhite),
              right: BorderSide(color: AppColors.glassWhite),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.userPrimary,
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: AppColors.glassWhite),

              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Price filter
                    _buildSectionTitle('Price'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._priceRanges.map((range) {
                      final isSelected =
                          _minPrice == range.min && _maxPrice == range.max;
                      return _buildCheckboxTile(
                        label: range.label,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _minPrice = 0;
                              _maxPrice = 200000;
                            } else {
                              _minPrice = range.min;
                              _maxPrice = range.max;
                            }
                          });
                        },
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),

                    // Brand filter (dynamic)
                    if (_provider.availableBrands.isNotEmpty) ...[
                      _buildSectionTitle('Brand'),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _provider.availableBrands.map((brand) {
                          final isSelected = _selectedBrands.contains(brand);
                          return FilterChip(
                            label: Text(brand),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedBrands.add(brand);
                                } else {
                                  _selectedBrands.remove(brand);
                                }
                              });
                            },
                            selectedColor:
                                AppColors.userPrimary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.userPrimary,
                            backgroundColor: AppColors.surfaceVariant,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.userPrimary
                                  : AppColors.glassWhite,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.userPrimary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Customer Rating
                    _buildSectionTitle('Customer Ratings'),
                    const SizedBox(height: AppSpacing.sm),
                    ...[4.0, 3.0, 2.0, 1.0].map((rating) {
                      final isSelected = _minRating == rating;
                      return _buildCheckboxTile(
                        label: '${rating.toInt()}\u2605 & above',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _minRating = isSelected ? 0 : rating;
                          });
                        },
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),

                    // Discount
                    _buildSectionTitle('Discount'),
                    const SizedBox(height: AppSpacing.sm),
                    ...[10.0, 20.0, 30.0, 40.0, 50.0].map((discount) {
                      final isSelected = _minDiscount == discount;
                      return _buildCheckboxTile(
                        label: '${discount.toInt()}% or more',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _minDiscount = isSelected ? 0 : discount;
                          });
                        },
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),

                    // Availability
                    _buildSectionTitle('Availability'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCheckboxTile(
                      label: 'Exclude Out of Stock',
                      isSelected: _inStockOnly,
                      onTap: () {
                        setState(() => _inStockOnly = !_inStockOnly);
                      },
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.glassWhite),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearAll,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.glassWhite),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.userPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.userPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.userPrimary
                      : AppColors.textTertiary,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
