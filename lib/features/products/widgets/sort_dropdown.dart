import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

enum SortOption {
  popularity('Popularity'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  newestFirst('Newest First');

  final String label;
  const SortOption(this.label);
}

class SortDropdown extends StatelessWidget {
  final SortOption selectedSort;
  final ValueChanged<SortOption> onSortChanged;

  const SortDropdown({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassWhite),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          value: selectedSort,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 20,
          ),
          isDense: true,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: AppColors.surfaceLight,
          items: SortOption.values.map((option) {
            return DropdownMenuItem<SortOption>(
              value: option,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForSort(option),
                    size: 16,
                    color: option == selectedSort
                        ? AppColors.userPrimary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option.label,
                    style: TextStyle(
                      color: option == selectedSort
                          ? AppColors.userPrimary
                          : AppColors.textPrimary,
                      fontWeight: option == selectedSort
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onSortChanged(value);
            }
          },
        ),
      ),
    );
  }

  IconData _getIconForSort(SortOption option) {
    switch (option) {
      case SortOption.popularity:
        return Icons.trending_up;
      case SortOption.priceLowToHigh:
        return Icons.arrow_upward;
      case SortOption.priceHighToLow:
        return Icons.arrow_downward;
      case SortOption.newestFirst:
        return Icons.access_time;
    }
  }
}
